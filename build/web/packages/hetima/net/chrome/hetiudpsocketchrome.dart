part of hetima_cl;

class HetiUdpSocketChrome extends HetiUdpSocket {
  
  chrome.CreateInfo _info = null;
  async.StreamController<HetiReceiveUdpInfo> receiveStream = new async.StreamController();
  HetiUdpSocketChrome.empty() {
  }

  async.Future<core.int> bind(core.String address, core.int port) {
    chrome.sockets.udp.onReceive.listen(onReceiveInternal);
    async.Completer<core.int> completer = new async.Completer();
    chrome.sockets.udp.create().then((chrome.CreateInfo info) {
      _info = info;
      HetiChromeSocketManager.getInstance().addUdp(info.socketId, this);
      return chrome.sockets.udp.setMulticastLoopbackMode(_info.socketId, true);
    }).then((v) {
      return chrome.sockets.udp.bind(_info.socketId, address, port);
    }).then((core.int v) {
      completer.complete(v);
    }).catchError((e) {
      completer.completeError(e);
    });
    return completer.future;
  }

  void onReceiveInternal(chrome.ReceiveInfo info){
    js.JsObject s= info.toJs();
    core.String remoteAddress = s["remoteAddress"];
    core.int remotePort = s["remotePort"];
    receiveStream.add(new HetiReceiveUdpInfo(info.data.getBytes(), remoteAddress, remotePort));
  }

  async.Future close() {
    HetiChromeSocketManager.getInstance().removeUdp(_info.socketId);
    return chrome.sockets.udp.close(_info.socketId);
  }

  async.Stream<HetiReceiveUdpInfo> onReceive() {
   return receiveStream.stream;
  }

  async.Future<HetiUdpSendInfo> send(core.List<core.int> buffer, core.String address, core.int port) {
    async.Completer<HetiUdpSendInfo> completer = new async.Completer();
    chrome.sockets.udp.send(_info.socketId, new chrome.ArrayBuffer.fromBytes(buffer), address, port).then((chrome.SendInfo info) {
      completer.complete(new HetiUdpSendInfo(info.resultCode));      
    });
    return completer.future;
  }
}
