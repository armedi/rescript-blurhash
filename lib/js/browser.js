import { toDataURL } from '../../src/BlurHash_Js.bs';
export * from '../../src/BlurHash_Js.bs';

// check if running on main thread
if (!!self.document) {
  function displayBlurred(image) {
    image.dataset.src = image.dataset.src || image.getAttribute('src');
    var dataURL = toDataURL(image.dataset.blurhash, 32, 32);
    image.setAttribute('src', dataURL);

    var $image = new Image();
    $image.setAttribute('src', image.dataset.src);
    $image.addEventListener('load', function () {
      image.setAttribute('src', image.dataset.src);
    });
  }

  document.addEventListener('DOMContentLoaded', function () {
    var images = document.querySelectorAll('img[data-blurhash]');
    images.forEach((image) => displayBlurred(image));
  });

  if ('MutationObsever' in window) {
    var observer = new MutationObserver(function (mutations) {
      for (var mutation of mutations) {
        if (
          mutation.type === 'childList' &&
          mutation.target === document.body
        ) {
          mutation.addedNodes.forEach((node) => {
            node.tagName === 'IMG' &&
              node.hasAttribute('data-blurhash') &&
              displayBlurred(node);
          });
        }
      }
    });

    observer.observe(document.body || document.documentElement, {
      childList: true,
      subtree: true,
    });
  }
}
