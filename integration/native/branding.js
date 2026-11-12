/* OfficeFlow product identity. Component attribution remains in LICENSE.html. */
var brandProductName = (function () {
  var name = new URLSearchParams(window.location.search).get('officeflowApp');
  return ['WordFlow', 'CellFlow', 'SlideFlow'].indexOf(name) >= 0 ? name : 'OfficeFlow';
})();
var brandProductURL = 'https://hasbreo.com/officeflow/';
window.addEventListener('load', function () {
  var observer;
  function attachIdentity() {
    var logo = document.querySelector('#document-header > a');
    if (!logo) return false;
    logo.setAttribute('data-cooltip', brandProductName);
    logo.setAttribute('aria-label', brandProductName + ' website');
    logo.setAttribute('href', brandProductURL);
    logo.addEventListener('click', function (event) {
      event.preventDefault();
      window.open(brandProductURL, '_blank');
    });
    if (observer) observer.disconnect();
    return true;
  }
  if (!attachIdentity()) {
    observer = new MutationObserver(attachIdentity);
    observer.observe(document.body, {childList: true, subtree: true});
    setTimeout(function () {observer.disconnect();}, 60000);
  }
});
