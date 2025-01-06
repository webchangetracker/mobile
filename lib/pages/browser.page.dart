import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class BrowserPage extends StatefulWidget {
  const BrowserPage({
    super.key,
    required this.initialUrl,
    this.onSelectorSelected,
  });

  final String initialUrl;
  final void Function(String url, String selector)? onSelectorSelected;

  @override
  State<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends State<BrowserPage> {
  final GlobalKey webViewKey = GlobalKey();

  InAppWebViewController? webViewController;
  InAppWebViewSettings settings = InAppWebViewSettings(
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
      iframeAllow: "camera; microphone",
      iframeAllowFullscreen: true);

  PullToRefreshController? pullToRefreshController;
  String url = "";
  double progress = 0;
  final urlController = TextEditingController();
  bool isSelectionModeActive = false;

  final String injectedJS = '''
    function enableDivSelection() {
      document.querySelectorAll('*').forEach(el => {
        el.style.removeProperty('outline');
        el.removeEventListener('click', clickHandler);
      });
      
      document.querySelectorAll('*').forEach(el => {
        el.style.outline = '1px solid red';
        el.addEventListener('click', clickHandler);
      });
    }

    function disableDivSelection() {
      document.querySelectorAll('*').forEach(el => {
        el.style.removeProperty('outline');
        el.removeEventListener('click', clickHandler);
      });
    }

    function clickHandler(e) {
      e.preventDefault();
      e.stopPropagation();
      
      let element = e.target;
      let selector = getCssSelector(element);
      
      const originalBg = element.style.backgroundColor;
      
      element.style.transition = 'background-color 0.3s ease';
      element.style.backgroundColor = '#ffeb3b';
      
      setTimeout(() => {
        element.style.backgroundColor = originalBg;
        element.style.transition = '';
      }, 1000);

      window.flutter_inappwebview.callHandler('onElementSelected', selector);
    }

    function getCssSelector(el) {
      let path = [];
      while (el.nodeType === Node.ELEMENT_NODE) {
        let selector = el.nodeName.toLowerCase();
        if (el.id) {
          selector += '#' + el.id;
          path.unshift(selector);
          break;
        } else {
          let sib = el, nth = 1;
          while (sib.previousElementSibling) {
            sib = sib.previousElementSibling;
            if (sib.nodeName.toLowerCase() === selector) nth++;
          }
          if (nth !== 1) selector += ":nth-of-type("+nth+")";
        }
        path.unshift(selector);
        el = el.parentNode;
      }
      return path.join(' > ');
    }
  ''';

  @override
  void initState() {
    super.initState();

    pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(
        color: Colors.blue,
      ),
      onRefresh: () async {
        if (defaultTargetPlatform == TargetPlatform.android) {
          webViewController?.reload();
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          webViewController?.loadUrl(
              urlRequest: URLRequest(url: await webViewController?.getUrl()));
        }
      },
    );
  }

  void toggleSelectionMode() {
    setState(() {
      isSelectionModeActive = !isSelectionModeActive;
    });

    if (isSelectionModeActive) {
      webViewController?.evaluateJavascript(source: 'enableDivSelection()');
    } else {
      webViewController?.evaluateJavascript(source: 'disableDivSelection()');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Browse URL"),
        actions: [
          IconButton(
            icon: Icon(
              isSelectionModeActive ? Icons.cancel : Icons.select_all,
              color: isSelectionModeActive ? Colors.red : null,
            ),
            onPressed: toggleSelectionMode,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search)),
              controller: urlController,
              keyboardType: TextInputType.url,
              onSubmitted: (value) {
                var url = WebUri(value);
                if (url.scheme.isEmpty) {
                  url = WebUri("https://www.google.com/search?q=$value");
                }
                webViewController?.loadUrl(urlRequest: URLRequest(url: url));
              },
            ),
            Expanded(
              child: Stack(
                children: [
                  InAppWebView(
                    key: webViewKey,
                    initialUrlRequest:
                        URLRequest(url: WebUri(widget.initialUrl)),
                    initialSettings: settings,
                    pullToRefreshController: pullToRefreshController,
                    onWebViewCreated: (controller) {
                      webViewController = controller;

                      controller.addJavaScriptHandler(
                        handlerName: 'onElementSelected',
                        callback: (args) {
                          if (args.isNotEmpty) {
                            ScaffoldMessenger.of(context)
                                .removeCurrentSnackBar();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Selected element: ${args[0]}'),
                                action: SnackBarAction(
                                  label: 'Use',
                                  onPressed: () {
                                    widget.onSelectorSelected?.call(
                                        urlController.text, args[0].toString());
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                            );
                          }
                        },
                      );
                    },
                    onLoadStart: (controller, url) {
                      setState(() {
                        this.url = url.toString();
                        urlController.text = this.url;
                      });
                    },
                    onPermissionRequest: (controller, request) async {
                      return PermissionResponse(
                          resources: request.resources,
                          action: PermissionResponseAction.GRANT);
                    },
                    onLoadStop: (controller, url) async {
                      pullToRefreshController?.endRefreshing();
                      setState(() {
                        this.url = url.toString();
                        urlController.text = this.url;
                      });

                      await controller.evaluateJavascript(source: injectedJS);
                    },
                    onReceivedError: (controller, request, error) {
                      pullToRefreshController?.endRefreshing();
                    },
                    onProgressChanged: (controller, progress) {
                      if (progress == 100) {
                        pullToRefreshController?.endRefreshing();
                      }
                      setState(() {
                        this.progress = progress / 100;
                        urlController.text = url;
                      });
                    },
                    onUpdateVisitedHistory: (controller, url, androidIsReload) {
                      setState(() {
                        this.url = url.toString();
                        urlController.text = this.url;
                      });
                    },
                    onConsoleMessage: (controller, consoleMessage) {
                      if (kDebugMode) {
                        print(consoleMessage);
                      }
                    },
                  ),
                  progress < 1.0
                      ? LinearProgressIndicator(value: progress)
                      : Container(),
                ],
              ),
            ),
            ButtonBar(
              alignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  child: const Icon(Icons.arrow_back),
                  onPressed: () {
                    webViewController?.goBack();
                  },
                ),
                ElevatedButton(
                  child: const Icon(Icons.arrow_forward),
                  onPressed: () {
                    webViewController?.goForward();
                  },
                ),
                ElevatedButton(
                  child: const Icon(Icons.home),
                  onPressed: () {
                    var url = WebUri("https://www.google.com/");
                    webViewController?.loadUrl(
                        urlRequest: URLRequest(url: url));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
