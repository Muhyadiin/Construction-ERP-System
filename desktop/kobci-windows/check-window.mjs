// Inspect the actual installed WebView on the disposable Windows runner.
const failure = process.argv[2] === 'failure';
const until = Date.now() + (failure ? 150_000 : 780_000);
const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
const expression = failure
  ? "document.querySelector('#status.error') !== null && document.querySelector('#copylogbtn')?.offsetWidth > 0"
  : "location.hostname === '127.0.0.1' && (document.querySelector('#root')?.innerText.trim().length || 0) > 30";

async function displayed(target) {
  const socket = new WebSocket(target.webSocketDebuggerUrl);
  try {
    return await new Promise((resolve) => {
      const timer = setTimeout(() => resolve(false), 3000);
      socket.onopen = () => socket.send(JSON.stringify({
        id: 1, method: 'Runtime.evaluate', params: { expression, returnByValue: true },
      }));
      socket.onmessage = (event) => {
        const data = JSON.parse(event.data);
        if (data.id === 1) {
          clearTimeout(timer);
          resolve(data.result?.result?.value === true);
        }
      };
      socket.onerror = () => { clearTimeout(timer); resolve(false); };
    });
  } finally {
    if (socket.readyState === WebSocket.OPEN) socket.close();
  }
}

let lastTargets = [];
while (Date.now() < until) {
  try {
    const res = await fetch('http://127.0.0.1:9338/json/list', { signal: AbortSignal.timeout(3000) });
    const pages = (await res.json()).filter((page) => page.type === 'page');
    lastTargets = pages.map((page) => page.url.split('?')[0]);
    for (const page of pages) {
      if (await displayed(page)) {
        console.log(failure ? 'Native window displayed the startup error and Copy log action.'
          : 'The installed WebView rendered the ERP application from the local server.');
        process.exit(0);
      }
    }
  } catch { /* The native WebView may still be starting or navigating. */ }
  await delay(1500);
}
throw Error('Window did not reach the expected state. Last visible targets: ' + lastTargets.join(', '));
