part of hetima;

class TorrentClient {
  static final int LOCAL_PORT_MIN = 18081;
  static final int LOCAL_PORT_MAX = 18091;
  static final int REMOTE_PORT_MIN = 18081;
  static final int REMOTE_PORT_MAX = 18091;

  String initialIP = "0.0.0.0";
  String localIP = "0.0.0.0";
  String remoteIP = "0.0.0.0";
  int localPort = LOCAL_PORT_MIN;
  int remotePort = LOCAL_PORT_MIN;

  HetiSocketBuilder _socketBuilder;
  UpnpPortMappingSample _portMapping;
  //client.event = hetima.TrackerUrl.VALUE_EVENT_STARTED;
  //client.peerID = peerId;
  TorrentClient(HetiSocketBuilder builder) {
    _socketBuilder = builder;
    _portMapping = new UpnpPortMappingSample(_socketBuilder);
  }

  void start() {
    startServer().then((d){
      startPortMapping().then((e){
        print("#### server : remote:"+remoteIP+":"+remotePort.toString());
        print("#### server : local:"+localIP+":"+localPort.toString());
      });
    });
  }

  async.Future<Object> startServer() {
    async.Completer<Object> completer = new async.Completer();
    bind() {
      _socketBuilder.startServer(localIP, localPort).then((HetiServerSocket socket) {
        completer.complete({});
        socket.onAccept().listen((HetiSocket s) {
          s.onReceive().listen((HetiReceiveInfo i) {
            s.send(convert.UTF8.encode("test")).then((HetiSendInfo i) {
              s.close();
            });
          });
        });
      }).catchError((e) {
        if (localPort > LOCAL_PORT_MAX) {
          completer.completeError(e);
        } else {
          localPort++;
          bind();
        }
      });
    }
    bind();
    return completer.future;
  }


  async.Future<Object> startPortMapping() {
    async.Completer<Object> completer = new async.Completer();
    portMapping() {
      return _portMapping.addPortMapping(localIP, localPort, remotePort, UPnpPPPDevice.VALUE_PORT_MAPPING_PROTOCOL_TCP)
           .then((UpnpPortMappingResult r) {
         if(r.result == UpnpPortMappingResult.OK_MAPPING) {
           r.deviceList.first.requestGetExternalIPAddress().then((String address) {
             remoteIP = address;
             completer.complete(address);             
           }).catchError((e){
             completer.completeError(e);
           });
           return;
         }
         if(remotePort < LOCAL_PORT_MAX) {
           remotePort++;
           portMapping();
         } else {
           completer.complete({});
         }
       }).catchError((e){
        completer.completeError(e);
      });
    };

    _socketBuilder.getNetworkInterfaces().then((List<HetiNetworkInterface> il) {
      bool foundNetworkInterfalce = false;
      for (HetiNetworkInterface i in il) {
        if ("127.0.0.7" == i.address || "0.0.0.0" == i.address) {
          continue;
        }
        if (i.prefixLength == 24) {
          localIP = i.address;
          foundNetworkInterfalce = true;
          break;
        }
      }
      if (!foundNetworkInterfalce) {
        completer.completeError({});
      } else {
        portMapping();
      }
    });
    return completer.future;
  }
  async.Future<Object> handshake() {

  }

}
