part of hetima;
class HetiSocketBuilderMock extends HetiSocketBuilder {
  HetiSocket createClient() {
    return null;
  }

  HetiUdpSocket createUdpClient() {
    return null;
  }

  async.Future<HetiServerSocket> startServer(String address, int port) {
    return null;
  }
}

class HetiSocketManagerMock {
  static HetiSocketManagerMock _sinst = new HetiSocketManagerMock();

  List<HetiSocketMock> _map = new List();

  void addHetiSocket(HetiSocketMock socket) {
    if (_map.contains(socket)) {
      _map.remove(socket);
    }
    _map.add(socket);
  }
  HetiSocketMock getFromAddress(String host, int port) {
    for (HetiSocketMock s in _map) {
      if (s.localAddress == host && s.localPort == port) {
        return s;
      }
    }
    return null;
  }

  void removeHetiSocket(HetiSocketMock socket) {
    _map.remove(socket.id);
  }

  static HetiSocketManagerMock getInstance() {
    return _sinst;
  }
}

class HetiSocketMock extends HetiSocket {
  static int _id = 0;

  String id = "";
  String remoteAddress = "";
  int remotePort = 0;
  String localAddress = "";
  int localPort = 0;
  async.StreamController _controller = new async.StreamController();
  HetiSocketMock _remoteSock = null;

  HetiSocketMock() {
    id = (_id++).toString();
  }

  @override
  void close() {
    super.close();
    HetiSocketManagerMock.getInstance().removeHetiSocket(this);
    _remoteSock = null;
  }

  @override
  async.Future<HetiSocket> connect(String peerAddress, int peerPort) {
    async.Completer<HetiSocket> completer = new async.Completer();
    HetiSocketMock mock = HetiSocketManagerMock.getInstance().getFromAddress(remoteAddress, remotePort);
    if (mock == null) {
      completer.completeError({});
    } else {
      HetiSocketMock socket = new HetiSocketMock();
      socket._remoteSock = mock;
      completer.complete(socket);
    }

    return completer.future;
  }

  @override
  async.Stream<HetiReceiveInfo> onReceive() {
    return _controller.stream;
  }

  void onReceiveInternal(List<int> buffer) {
    int length = buffer.length;
    int start = 0;
    for (int i = 0; start < length; i++) {
      int end = start + 4096;
      if (end > length) {
        end = length;
      }
      _controller.add(new HetiReceiveInfo(buffer.sublist(start, end)));
      start = end;
    }
  }

  @override
  async.Future<HetiSendInfo> send(List<int> data) {
    async.Completer completer = new async.Completer();
    if (isClosed || _remoteSock.isClosed) {
      completer.completeError({});
    } else {
      _remoteSock.onReceiveInternal(data);
      completer.complete(new HetiSendInfo(0));
    }
    return completer.future;
  }
}
