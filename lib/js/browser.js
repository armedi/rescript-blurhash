import { toDataURL } from '../../src/BlurHash_Js.bs';
export * from '../../src/BlurHash_Js.bs';

// check if running on main thread
if (!!self.document) {
  document.addEventListener('DOMContentLoaded', () => {
    document.querySelectorAll('img[data-blurhash]').forEach(displayBlurred);
  });

  if ('MutationObsever' in window) {
    const observer = new MutationObserver((mutations) => {
      for (const mutation of mutations) {
        if (
          mutation.type === 'childList' &&
          mutation.target === document.body
        ) {
          mutation.addedNodes.forEach(
            (node) =>
              node.tagName === 'IMG' &&
              node.hasAttribute('data-blurhash') &&
              displayBlurred(node)
          );
        }
      }
    });

    observer.observe(document.body || document.documentElement, {
      childList: true,
      subtree: true,
    });
  }

  function displayBlurred(image) {
    setTimeout(() => {
      const src = image.getAttribute('src');

      const $image = new Image();
      $image.setAttribute('src', src);
      $image.addEventListener('load', () => image.setAttribute('src', src), {
        once: true,
      });

      const dataURL = toDataURL(image.dataset.blurhash, 32, 32);
      image.setAttribute('src', dataURL);
    });
  }
}
