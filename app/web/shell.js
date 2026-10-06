// Downloads and starts the app, showing progress, and swaps the loading
// screen for it. If the app cannot start, the screen stays and says why,
// instead of leaving a blank page.
(async () => {
  const loading = document.getElementById('loading');
  const screen = document.getElementById('screen');
  const status = document.getElementById('status');
  const progress = document.getElementById('progress');
  const { wasm, wasmGz } = document.currentScript.dataset;

  const fail = (message) => {
    screen.hidden = true;
    loading.hidden = false;
    progress.hidden = true;
    status.textContent = message;
  };

  /** The response body as a stream that reports how much has arrived. */
  function counted(response) {
    const total = Number(response.headers.get('Content-Length')) || 0;
    let received = 0;
    return response.body.pipeThrough(
      new TransformStream({
        transform(chunk, controller) {
          received += chunk.byteLength;
          if (total) {
            const percent = Math.min(100, Math.round((received / total) * 100));
            progress.value = percent;
            status.textContent = `Loading… ${percent}%`;
          }
          controller.enqueue(chunk);
        },
      }),
    );
  }

  /**
   * Fetches the WebAssembly module. The gzip copy is preferred and unpacked
   * here, because some hosts (CloudFront, and so AWS Amplify) do not compress
   * files over 10 MB themselves. Falls back to the plain file.
   */
  async function fetchModule() {
    if (wasmGz && typeof DecompressionStream === 'function') {
      try {
        const response = await fetch(wasmGz);
        if (response.ok) {
          const unpacked = counted(response).pipeThrough(new DecompressionStream('gzip'));
          return await WebAssembly.compile(await new Response(unpacked).arrayBuffer());
        }
      } catch (error) {
        console.warn('Compressed module unavailable, using the uncompressed one.', error);
      }
    }
    const response = await fetch(wasm);
    if (!response.ok) throw new Error(`Could not download ${wasm}: ${response.status}`);
    return WebAssembly.compile(await new Response(counted(response)).arrayBuffer());
  }

  /**
   * Touchpads report scrolling in fractions of a pixel, many times a second.
   * The app reads wheel input in whole pixels and would discard anything
   * smaller, so a gentle two-finger scroll would not move the page at all.
   * This holds back each fraction and passes the scroll on as whole pixels.
   */
  function passWheelAsWholePixels() {
    const rest = { x: 0, y: 0 };
    let last = 0;
    window.addEventListener(
      'wheel',
      (event) => {
        // Leave alone: events re-sent below, and pinch-zoom (Ctrl + wheel).
        if (!event.isTrusted || event.ctrlKey) return;

        // Some browsers (Firefox with a mouse wheel) report lines or pages instead
        // of pixels. Convert, so that every browser scrolls the same distance.
        const unit = event.deltaMode === WheelEvent.DOM_DELTA_LINE ? 100 / 3 : event.deltaMode === WheelEvent.DOM_DELTA_PAGE ? window.innerHeight * 0.85 : 1;
        const dx = event.deltaX * unit;
        const dy = event.deltaY * unit;
        if (unit === 1 && Number.isInteger(dx) && Number.isInteger(dy) && rest.x === 0 && rest.y === 0) return;

        event.stopImmediatePropagation();
        event.preventDefault();

        // A pause or a change of direction starts a new gesture; stale fractions are dropped.
        if (event.timeStamp - last > 250 || rest.x * dx < 0 || rest.y * dy < 0) rest.x = rest.y = 0;
        last = event.timeStamp;
        rest.x += dx;
        rest.y += dy;
        const deltaX = Math.trunc(rest.x);
        const deltaY = Math.trunc(rest.y);
        if (deltaX === 0 && deltaY === 0) return;
        rest.x -= deltaX;
        rest.y -= deltaY;

        // The app's canvas is inside a shadow tree; composedPath gives the real target.
        const target = event.composedPath()[0] ?? event.target;
        target.dispatchEvent(
          new WheelEvent('wheel', {
            deltaX,
            deltaY,
            deltaMode: WheelEvent.DOM_DELTA_PIXEL,
            clientX: event.clientX,
            clientY: event.clientY,
            screenX: event.screenX,
            screenY: event.screenY,
            shiftKey: event.shiftKey,
            altKey: event.altKey,
            metaKey: event.metaKey,
            buttons: event.buttons,
            view: window,
            bubbles: true,
            cancelable: true,
            composed: true,
          }),
        );
      },
      { capture: true, passive: false },
    );
  }

  passWheelAsWholePixels();

  try {
    await qtLoad({
      qt: {
        module: fetchModule().then((module) => {
          status.textContent = 'Starting…';
          return module;
        }),
        onLoaded: () => {
          loading.hidden = true;
          screen.hidden = false;
        },
        onExit: () => fail('The site stopped unexpectedly. Reload the page to try again.'),
        entryFunction: window.lsitools_entry,
        containerElements: [screen],
      },
    });
  } catch (error) {
    console.error(error);
    fail('The site could not start in this browser. It needs a current browser with WebAssembly and WebGL enabled.');
  }
})();
