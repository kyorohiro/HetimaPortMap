part of hetima_cl;

class HetiSocketBuilderChrome extends HetiSocketBuilder {

  HetiSocket createClient() {
    return new HetiSocketChrome.empty();
  }

  async.Future<HetiServerSocket> startServer(core.String address, core.int port) {
    return HetiServerSocketChrome.startServer(address, port);
  }

  HetiUdpSocket createUdpClient() {
    return new HetiUdpSocketChrome.empty();
  }

  async.Future<core.List<HetiNetworkInterface>> getNetworkInterfaces() {
    async.Completer<core.List<HetiNetworkInterface>> completer = new async.Completer();
    core.List<HetiNetworkInterface> interfaceList = new core.List();
    chrome.system.network.getNetworkInterfaces().then((core.List<chrome.NetworkInterface> nl) {
      for (chrome.NetworkInterface i in nl) {
        HetiNetworkInterface inter = new HetiNetworkInterface();
        inter.address = i.address;
        inter.prefixLength = i.prefixLength;
        interfaceList.add(inter);
      }
      completer.complete(interfaceList);
    }).catchError((e){
      completer.completeError(e);
    });
    return completer.future;
  }
}

class HetiChromeSocketManager {
  core.Map<core.int, HetiServerSocket> _serverList = new core.Map();
  core.Map<core.int, HetiSocket> _clientList = new core.Map();
  core.Map<core.int, HetiUdpSocket> _udpList = new core.Map();
  static final HetiChromeSocketManager _instance = new HetiChromeSocketManager._internal();
  factory HetiChromeSocketManager() {
    return _instance;
  }

  HetiChromeSocketManager._internal() {
    manageServerSocket();
  }

  static HetiChromeSocketManager getInstance() {
    return _instance;
  }

  void manageServerSocket() {
    chrome.sockets.tcpServer.onAccept.listen((chrome.AcceptInfo info) {
      core.print("--accept ok " + info.socketId.toString() + "," + info.clientSocketId.toString());
      HetiServerSocketChrome server = _serverList[info.socketId];
      if (server != null) {
        server.onAcceptInternal(info);
      }
    });

    chrome.sockets.tcpServer.onAcceptError.listen((chrome.AcceptErrorInfo info) {
      core.print("--accept error");
    });

    core.bool closeChecking = false;
    chrome.sockets.tcp.onReceive.listen((chrome.ReceiveInfo info) {
     // core.print("--receive " + info.socketId.toString() + "," + info.data.getBytes().length.toString());
      HetiSocketChrome socket = _clientList[info.socketId];
      if (socket != null) {
        socket.onReceiveInternal(info);
      }
    });
    chrome.sockets.tcp.onReceiveError.listen((chrome.ReceiveErrorInfo info) {
      core.print("--receive error " + info.socketId.toString() + "," + info.resultCode.toString());
      HetiSocketChrome socket = _clientList[info.socketId];
      if (socket != null) {
        closeChecking = true;
        socket.close();
      }
    });
    
    chrome.sockets.udp.onReceive.listen((chrome.ReceiveInfo info) {
      HetiUdpSocketChrome socket = _udpList[info.socketId];
      if (socket != null) {
        socket.onReceiveInternal(info);
      }
    });
    chrome.sockets.udp.onReceiveError.listen((chrome.ReceiveErrorInfo info) {
      core.print("--receive udp error " + info.socketId.toString() + "," + info.resultCode.toString());
    });
  }

  void addServer(chrome.CreateInfo info, HetiServerSocketChrome socket) {
    _serverList[info.socketId] = socket;
  }

  void removeServer(chrome.CreateInfo info) {
    _serverList.remove(info.socketId);
  }

  void addClient(core.int socketId, HetiSocketChrome socket) {
    _clientList[socketId] = socket;
  }

  void removeClient(core.int socketId) {
    _clientList.remove(socketId);
  }

  void addUdp(core.int socketId, HetiUdpSocket socket) {
    _udpList[socketId] = socket;
  }

  void removeUdp(core.int socketId) {
    _udpList.remove(socketId);
  }

}

