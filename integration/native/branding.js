// SPDX-License-Identifier: MPL-2.0
/* HasOffice product identity. Component attribution remains in LICENSE.html. */
function officeFlowProductName() {
  var name = new URLSearchParams(window.location.search).get('officeflowApp');
  return ['HasWord', 'HasCell', 'HasSlides'].indexOf(name) >= 0 ? name : 'HasOffice';
}
var brandProductName = officeFlowProductName();
window.brandProductName = brandProductName;
var brandProductURL = 'https://hasbreo.com/hasoffice/';
window.addEventListener('load', function () {
  brandProductName = officeFlowProductName();
  window.brandProductName = brandProductName;
  // HasOffice supplies its own release/update experience. Do not open the
  // vendor's presentation window automatically when a document app starts.
  var welcome = window.L && window.L.Map && window.L.Map.Welcome;
  if (welcome) welcome.prototype.shouldWelcomeWithSlideshow = function () {return false;};
  var observer;
  function attachIdentity() {
    var logo = document.querySelector('#document-header > a');
    if (!logo) return false;
    var iconName = {HasWord:'hasword',HasCell:'hascell',HasSlides:'hasslides'}[brandProductName] || 'hasoffice';
    document.querySelectorAll('.document-logo, #product-logo, .img-coda-app-logo, #document-header > a').forEach(function(el){if(el.tagName==='IMG')el.src=iconName+'.svg';else el.style.setProperty('background-image', 'url('+iconName+'.svg)', 'important');});
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
