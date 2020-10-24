/**
 * convert image data from Uint8ClampedArray to dataURL
 * @param {Uint8ClampedArray} pixels - image pixels data.
 * @param {number} width - image width.
 * @param {number} height - image height.
 * @return {string} image dataURL.
 */
export function pixelsToDataURL(pixels, width, height) {
  const canvas = document.createElement('canvas');
  canvas.width = width;
  canvas.height = height;
  const ctx = canvas.getContext('2d');
  const imageData = ctx.createImageData(width, height);
  imageData.data.set(pixels);
  ctx.putImageData(imageData, 0, 0);

  return canvas.toDataURL();
}
