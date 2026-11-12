// Native OfficeFlow files open ready to edit. This only removes the initial
// viewing-mode preference; actual document permissions remain authoritative.
(() => {
  const url = new URL(window.location.href);
  const app = url.searchParams.get('officeflowApp');
  if (['WordFlow', 'CellFlow', 'SlideFlow'].includes(app) &&
      url.searchParams.get('permission') === 'edit' &&
      url.searchParams.get('startreadonly') === 'true' &&
      url.searchParams.get('welcome') !== 'true') {
    url.searchParams.delete('startreadonly');
    window.history.replaceState(window.history.state, '', url.href);
  }
})();
