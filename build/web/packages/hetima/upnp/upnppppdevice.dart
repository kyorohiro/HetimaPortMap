part of hetima;

class UPnpPPPDevice {
//  static final String KEY_SOAPACTION = "SOAPACTION";
  static final String KEY_SOAPACTION = "SOAPAction";
  static final String VALUE_PORT_MAPPING_PROTOCOL_UDP = "UDP";
  static final String VALUE_PORT_MAPPING_PROTOCOL_TCP = "TCP";
  static final int VALUE_ENABLE = 1;
  static final int VALUE_DISABLE = 0;

  UPnpDeviceInfo _base = null;
  String _serviceName = "WANPPPConnection";
  String _version = "1";

  UPnpPPPDevice(UPnpDeviceInfo base) {
    _base = base;

    String st = _base.getValue(UPnpDeviceInfo.KEY_ST, "WANIPConnection");
    if (st.contains("WANIPConnection")) {
      _serviceName = "WANIPConnection";
    }
    String b = "";
    List<String> v = st.replaceAll(" |\t|\r|\n", "").split(":");
    _version = v.last;
    print("${_version}");
  }

  /**
   * response.resultCode 
   *  200 OK
   *  402 Invalid Args See UPnP Device Architecture section on Control. 
   *  713 SpecifiedArrayIndexInvalid The specified array index is out of bounds 
   */
  async.Future<UPnpGetGenericPortMappingResponse> requestGetGenericPortMapping(int newPortMappingIndex, [int mode = MODE_POST, UPnpDeviceServiceInfo serviceInfo = null]) {
    async.Completer<String> completer = new async.Completer();
    if (getPPPService().length == 0) {
      completer.completeError({});
      return completer.future;
    }
    if (serviceInfo == null) {
      serviceInfo = getPPPService().first;
    }

    String requestBody = """<?xml version="1.0"?>\r\n<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><SOAP-ENV:Body><m:GetGenericPortMappingEntry xmlns:m="urn:schemas-upnp-org:service:${_serviceName}:${_version}"><NewPortMappingIndex>${newPortMappingIndex}</NewPortMappingIndex></m:GetGenericPortMappingEntry></SOAP-ENV:Body></SOAP-ENV:Envelope>\r\n""";
    String headerValue = """\"urn:schemas-upnp-org:service:${_serviceName}:${_version}#GetGenericPortMappingEntry\"""";

    request(serviceInfo, headerValue, requestBody, mode).then((UPnpPPPDeviceRequestResponse response) {
      completer.complete(new UPnpGetGenericPortMappingResponse(response));
    }).catchError((e) {
      completer.completeError(e);
    });
    return completer.future;
  }

  /**
   * return resultCode. if success then. return 200. ;
   */
  async.Future<int> requestAddPortMapping(int newExternalPort, String newProtocol, int newInternalPort, String newInternalClient, int newEnabled, String newPortMappingDescription, int newLeaseDuration, [int mode = MODE_POST, UPnpDeviceServiceInfo serviceInfo = null]) {
    async.Completer<int> completer = new async.Completer();
    if (getPPPService().length == 0) {
      completer.completeError({});
      return completer.future;
    }
    if (serviceInfo == null) {
      serviceInfo = getPPPService().first;
    }
    String headerValue = """\"urn:schemas-upnp-org:service:${_serviceName}:${_version}#AddPortMapping\"""";
    String requestBody = """<?xml version="1.0"?>\r\n<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><SOAP-ENV:Body><m:AddPortMapping xmlns:m="urn:schemas-upnp-org:service:${_serviceName}:${_version}">""" + """<NewRemoteHost></NewRemoteHost><NewExternalPort>${newExternalPort}</NewExternalPort><NewProtocol>${newProtocol}</NewProtocol><NewInternalPort>${newInternalPort}</NewInternalPort><NewInternalClient>${newInternalClient}</NewInternalClient><NewEnabled>${newEnabled}</NewEnabled><NewPortMappingDescription>${newPortMappingDescription}</NewPortMappingDescription><NewLeaseDuration>${newLeaseDuration}</NewLeaseDuration></m:AddPortMapping></SOAP-ENV:Body></SOAP-ENV:Envelope>\r\n""";

    request(serviceInfo, headerValue, requestBody, mode).then((UPnpPPPDeviceRequestResponse response) {
      if (response.resultCode == 200) {
        completer.complete(response.resultCode);
      } else {
        completer.complete(response.resultCode * -1);
      }
    }).catchError((e) {
      completer.completeError(e);
    });
    return completer.future;
  }

  async.Future<int> requestDeletePortMapping(int newExternalPort, String newProtocol, [int mode = MODE_POST, UPnpDeviceServiceInfo serviceInfo = null]) {
    async.Completer<int> completer = new async.Completer();
    if (getPPPService().length == 0) {
      completer.completeError({});
      return completer.future;
    }
    if (serviceInfo == null) {
      serviceInfo = getPPPService().first;
    }
    String requestBody = """<?xml version=\"1.0\"?>\r\n<SOAP-ENV:Envelope xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\" SOAP-ENV:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\"><SOAP-ENV:Body><m:DeletePortMapping xmlns:m=\"urn:schemas-upnp-org:service:${_serviceName}:${_version}\">""" + """<NewRemoteHost></NewRemoteHost><NewExternalPort>${newExternalPort}</NewExternalPort><NewProtocol>${newProtocol}</NewProtocol></m:DeletePortMapping></SOAP-ENV:Body></SOAP-ENV:Envelope>\r\n""";
    String headerValue = """\"urn:schemas-upnp-org:service:${_serviceName}:${_version}#DeletePortMapping\"""";
    request(serviceInfo, headerValue, requestBody, mode).then((UPnpPPPDeviceRequestResponse response) {
      if (response.resultCode == 200) {
        completer.complete(response.resultCode);
      } else {
        completer.complete(response.resultCode * -1);
      }
    }).catchError((e) {
      completer.completeError(e);
    });
    return completer.future;
  }


  async.Future<String> requestGetExternalIPAddress([int mode = MODE_POST, UPnpDeviceServiceInfo serviceInfo = null]) {
    async.Completer<String> completer = new async.Completer();
    if (getPPPService().length == 0) {
      completer.completeError({});
      return completer.future;
    }
    if (serviceInfo == null) {
      serviceInfo = getPPPService().first;
    }
    String headerValue = """\"urn:schemas-upnp-org:service:${_serviceName}:${_version}#GetExternalIPAddress\"""";
    String requestBody = """<?xml version="1.0"?>\r\n<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body><m:GetExternalIPAddress xmlns:m="urn:schemas-upnp-org:service:${_serviceName}:${_version}"></m:GetExternalIPAddress></s:Body></s:Envelope>\r\n""";

    request(serviceInfo, headerValue, requestBody, mode).then((UPnpPPPDeviceRequestResponse response) {
      xml.XmlDocument document = xml.parse(response.body);
      Iterable<xml.XmlElement> elements = document.findAllElements("NewExternalIPAddress");
      if (elements.length > 0) {
        completer.complete(elements.first.text);
      } else {
        completer.complete("");
      }
    }).catchError((e) {
      completer.completeError(e);
    });
    return completer.future;
  }

  List<UPnpDeviceServiceInfo> getPPPService() {
    List<UPnpDeviceServiceInfo> deviceInfo = [];
    for (UPnpDeviceServiceInfo info in _base.serviceList) {
      if (info.serviceType.contains("WANIPConnection") || info.serviceType.contains("WANPPPConnection")) {
        deviceInfo.add(info);
      }
    }
    return deviceInfo;
  }

  static const int MODE_M_POST = 0;
  static const int MODE_POST = 1;

  async.Future<UPnpPPPDeviceRequestResponse> request(UPnpDeviceServiceInfo info, String soapAction, String body, int mode) {
    async.Completer<UPnpPPPDeviceRequestResponse> completer = new async.Completer();
    HetiSocket socket = _base.getSocketBuilder().createClient();
    String location = _base.getValue(UPnpDeviceInfo.KEY_LOCATION, "");
    if ("" == location) {
      completer.completeError({});
      return completer.future;
    }
    HetiHttpClient client = new HetiHttpClient(_base.getSocketBuilder());
    HttpUrl url = HttpUrlDecoder.decodeUrl(location);
    String host = url.host;
    String path = "/";
    int port = url.port;
    if (_base.URLBase != null && _base.URLBase.length != 0) {
      HttpUrl urlBase = HttpUrlDecoder.decodeUrl(location);
      host = urlBase.host;
      path = urlBase.path;
      port = urlBase.port;
    }

    if(info.controlURL != null && info.controlURL.length != 0) {
      path = info.controlURL;
    }
    client.connect(host, port).then((int v) {
      if(mode == MODE_POST) {
      return client.post(path, convert.UTF8.encode(body), {
        KEY_SOAPACTION: soapAction,
        "Content-Type": "text/xml"
      });
      } else {
        return client.mpost(path, convert.UTF8.encode(body), {
          "MAN": "\"http://schemas.xmlsoap.org/soap/envelope/\"; ns=01",
          "01-SOAPACTION": soapAction,
          "Content-Type": "text/xml"
        });
      }
    }).then((HetiHttpClientResponse response) {
      return response.body.onFin().then((bool v) {
        return response.body.getLength();
      }).then((int length) {
        return response.body.getByteFuture(0, length);
      }).then((List<int> body) {
        print(convert.UTF8.decode(body));
        completer.complete(new UPnpPPPDeviceRequestResponse(response.message.line.statusCode, convert.UTF8.decode(body)));
      });
    }).catchError((e) {
      completer.completeError(e);
    });
    return completer.future;
  }
}

class UPnpPPPDeviceRequestResponse {
  UPnpPPPDeviceRequestResponse(int _resultCode, String _body) {
    body = _body;
    resultCode = _resultCode;
  }
  String body;
  int resultCode;
}

class UPnpGetGenericPortMappingResponse {
  static final String KEY_NewRemoteHost = "NewRemoteHost";
  static final String KEY_NewExternalPort = "NewExternalPort";
  static final String KEY_NewProtocol = "NewProtocol";
  static final String KEY_NewInternalPort = "NewInternalPort";
  static final String KEY_NewInternalClient = "NewInternalClient";
  static final String KEY_NewEnabled = "NewEnabled";
  static final String KEY_NewPortMappingDescription = "NewPortMappingDescription";
  static final String KEY_NewLeaseDuration = "NewLeaseDuration";

  UPnpPPPDeviceRequestResponse _response = null;
  UPnpGetGenericPortMappingResponse(UPnpPPPDeviceRequestResponse response) {
    _response = response;
  }

  int get resultCode => _response.resultCode;

  String getValue(String key, String defaultValue) {
    if (_response.resultCode != 200) {
      return defaultValue;
    }
    xml.XmlDocument document = xml.parse(_response.body);
    Iterable<xml.XmlElement> elements = document.findAllElements(key);
    if (elements == null || elements.length <= 0) {
      return defaultValue;
    }
    return elements.first.text;
  }

  @override
  String toString() {
    return _response.body.toString();
  }
  
}
