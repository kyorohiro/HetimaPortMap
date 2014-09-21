part of hetima_cl;


class HetiSocketChrome extends HetiSocket {
  core.int clientSocketId;
  async.StreamController<HetiReceiveInfo> _controller = new async.StreamController();

  HetiSocketChrome.empty() {
  }

  HetiSocketChrome(core.int _clientSocketId) {
    HetiChromeSocketManager.getInstance().addClient(_clientSocketId, this);
    chrome.sockets.tcp.setPaused(_clientSocketId, false);
    clientSocketId = _clientSocketId;
  }

  async.Stream<HetiReceiveInfo> onReceive() {
    return _controller.stream;
  }

  void onReceiveInternal(chrome.ReceiveInfo info) {
    //core.print("--receive " + info.socketId.toString());
    updateTime();
    core.List<core.int> tmp = info.data.getBytes();
    buffer.appendIntList(tmp, 0, tmp.length);
    _controller.add(new HetiReceiveInfo(info.data.getBytes()));
  }

  async.Future<HetiSendInfo> send(core.List<core.int> data) {
    updateTime();
    async.Completer<HetiSendInfo> completer = new async.Completer();
    new async.Future.sync(() {
      chrome.ArrayBuffer buffer = new chrome.ArrayBuffer.fromBytes(data);
      chrome.sockets.tcp.send(clientSocketId, buffer).then((chrome.SendInfo info) {
        updateTime();
        completer.complete(new HetiSendInfo(info.resultCode));
      });
    }).catchError((e) {
      completer.complete(new HetiSendInfo(-1999));
    });
    return completer.future;
  }

  async.Future<HetiSocket> connect(core.String peerAddress, core.int peerPort) {
    async.Completer<HetiSocket> completer = new async.Completer();
    new async.Future.sync(() {
      chrome.sockets.tcp.create().then((chrome.CreateInfo info) {
        chrome.sockets.tcp.connect(info.socketId, peerAddress, peerPort).then((core.int e) {
          {
            chrome.sockets.tcp.setPaused(info.socketId, false);
            clientSocketId = info.socketId;
            HetiChromeSocketManager.getInstance().addClient(info.socketId, this);
            completer.complete(this);
          }
        });
      });
    }).catchError((e) {
      core.print(e.toString());
      completer.complete(null);
    });
    return completer.future;
  }

  void close() {
    super.close();
    if (_isClose) {
      return;
    }
    updateTime();
    chrome.sockets.tcp.close(clientSocketId).then((d) {
      core.print("##closed()");
    });
    HetiChromeSocketManager.getInstance().removeClient(clientSocketId);
    _isClose = true;
  }
  core.bool _isClose = false;
}

