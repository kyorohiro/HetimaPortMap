part of hetima;

class UtpPacket {
  int type; //4
  int ver;  //4
  int extension; //8
  int connectionid; //16
  int timestampMicroseconds; //32;
  int timestampDifferenceMicroseconds; //32
  int wndSize; //32
  int seqNr; //16
  int ackNr; //16
  List<int> extensions;
  List<int> payload;
}
