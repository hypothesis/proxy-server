
/**
 * Monkey patches XMLHttpRequests to be routed through the proxy server.
 *
*/
patchXmlHttpRequests = function() {
  let open = XMLHttpRequest.prototype.open;
  XMLHttpRequest.prototype.open = function(method, url, async, user, psw) {
    if (url.startsWith("/") && !url.startsWith("//")) {
        url = window.viaUrl + url;
    }
    return open.call(this, method, url, async, user, psw);
  };
};

patchXmlHttpRequests();
