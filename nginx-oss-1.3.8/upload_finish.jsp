<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ page import="java.util.*,java.util.Map.*,java.io.*,java.util.regex.*"%>
<%@ page import="javax.imageio.ImageIO,java.awt.image.BufferedImage"%>
<%
	boolean debug = true;
	String domain = "http://192.168.0.30:50000/oss";
	String folder = "/alidata/oss";
	String ext="";	//扩展名：jpg|gif|bmp|png
	int size = 102400; //单位：KB,默认100MB，受服务器限制,限制大小
	int width = 0;	//图片限制宽度
	int height = 0;	//图片限制高度
	String user_id = "sys";//上传到服务器哪个用户下 
	String dir = "other";//上传到服务器的目录 
	String client = ""; //cross js upload,set client="js"
	
	if (request.getParameter("ext") != null) {
		ext = request.getParameter("ext").trim();
	}
	try{
		size = Integer.valueOf(request.getParameter("size"));
	}catch(Exception ex){
	}
	if (size <= 0){
		size = 102400;
	}
	try{
		width = Integer.valueOf(request.getParameter("width"));
	}catch(Exception ex){
	}
	if (width < 0){
		width = 0;
	}
	try{
		height = Integer.valueOf(request.getParameter("height"));
	}catch(Exception ex){
	}
	if (height < 0){
		height = 0;
	}
	if (request.getParameter("user_id") != null){
		user_id = request.getParameter("user_id").replace(" ","").replace("　","");
	}
	if ("".equals(user_id)){
		user_id = "sys";
	}
	if (request.getParameter("dir") != null){
		dir = request.getParameter("dir").replace(" ","").replace("　","");
	}
	if ("".equals(dir)){
		dir = "other";
	}
	
	long maxSize = size * 1024;
	
	List<String> inputControlNameList = new ArrayList<String>();
	TreeMap<String, String> fileInfoMap = null;
	
	if (request.getParameter("client") != null) {
		client = request.getParameter("client").trim();
	}
	BufferedInputStream bis = new BufferedInputStream(request.getInputStream());
	byte[] bytes = new byte[4096];
	int len = 0;
	StringBuffer sb = new StringBuffer();
	while ((len = bis.read(bytes)) != -1) {
		sb.append(new String(bytes));
	}
	
	/** firefox:
	-----------------------------611982811683
	Content-Disposition: form-data; name="pic_name"
	
	新建文本文档.txt
	-----------------------------611982811683
	Content-Disposition: form-data; name="pic_content_type"
	
	text/plain
	-----------------------------611982811683
	Content-Disposition: form-data; name="pic_path"
	
	/alidata/oss/tmp/0050528273
	-----------------------------611982811683
	Content-Disposition: form-data; name="pic_md5"
	
	b2be0c859ebe96cc085c3216e9cd47b5
	-----------------------------611982811683
	Content-Disposition: form-data; name="pic_size"
	
	134
	-----------------------------611982811683--
	*/
	/** 360webkit
	------WebKitFormBoundaryvIkAfjlixs0rEXLZ
	Content-Disposition: form-data; name="pic_name"

	3.png
	------WebKitFormBoundaryvIkAfjlixs0rEXLZ
	Content-Disposition: form-data; name="pic_content_type"

	image/png
	------WebKitFormBoundaryvIkAfjlixs0rEXLZ
	Content-Disposition: form-data; name="pic_path"

	/alidata/oss/tmp/0000000023
	------WebKitFormBoundaryvIkAfjlixs0rEXLZ
	Content-Disposition: form-data; name="pic_md5"

	eb0404dd11aaf7fcf8ae089468c74c90
	------WebKitFormBoundaryvIkAfjlixs0rEXLZ
	Content-Disposition: form-data; name="pic_size"

	11331
	------WebKitFormBoundaryvIkAfjlixs0rEXLZ--
	*/
	/** ios app
	--Boundary+965E13D019129B69
	Content-Disposition: form-data; name="pic_name"

	abc.jpg
	--Boundary+965E13D019129B69
	Content-Disposition: form-data; name="pic_content_type"

	application/octet-stream
	--Boundary+965E13D019129B69
	Content-Disposition: form-data; name="pic_path"

	/alidata/oss/tmp/0000000121
	--Boundary+965E13D019129B69
	Content-Disposition: form-data; name="pic_md5"

	6dabc8d70b6daa64d9b07bfbba0d0e2e
	--Boundary+965E13D019129B69
	Content-Disposition: form-data; name="pic_size"

	43807
	--Boundary+965E13D019129B69--
	*/
	/** appcan
	--3b65cf42-8863-4d00-a96c-90aa7749068f
	Content-Disposition: form-data; name="test_name"

	scan20170331165122.jpg
	--3b65cf42-8863-4d00-a96c-90aa7749068f
	Content-Disposition: form-data; name="test_content_type"

	application/octet-stream; charset=utf-8
	--3b65cf42-8863-4d00-a96c-90aa7749068f
	Content-Disposition: form-data; name="test_path"

	/alidata/oss/tmp/0000000007
	--3b65cf42-8863-4d00-a96c-90aa7749068f
	Content-Disposition: form-data; name="test_md5"

	718528d711bd9d93b839d247ea03f31f
	--3b65cf42-8863-4d00-a96c-90aa7749068f
	Content-Disposition: form-data; name="test_size"

	130784
	--3b65cf42-8863-4d00-a96c-90aa7749068f--
	*/

	fileInfoMap = new TreeMap<String, String>();
	String[] ss = sb.toString().split("Content-Disposition: form-data; name=\"");
	String[] st = null;
	for (int i = 0; i < ss.length; i++) {
		if (ss[i].indexOf("\"") != -1) {
			while (ss[i].indexOf("----------") != -1){
				ss[i] = ss[i].replace("----------","-----");
			}
			st = ss[i].split("-----");
			//ios app upload begin
			if (st.length != 2){
				st = ss[i].split("--Boundary");
			}
			//ios app upload end
			//appcan begin
			if (st.length != 2){
				st = ss[i].split("--");
			}
			//appcan end
			//okhttp begin
			if (st.length == 3){
				st = ss[i].trim().substring(0, ss[i].trim().length() - 2).split("--");
			}
			//okhttp end
			if (st.length == 2) {
				st = st[0].split("\"");
				if (st.length == 2) {
					fileInfoMap.put(st[0].trim(), st[1].trim());
					if (st[0].trim().endsWith("_name")) {
						inputControlNameList.add(st[0].trim().substring(0, st[0].trim().length() - 5));
					}
				}
			}
		}
	}

	if (fileInfoMap.size() == 0){
		if (debug){
			System.out.println("");
			System.out.println("file upload failure,request inputstream parse error!"); 
			System.out.println("");
			System.out.println(sb.toString()); 
		}
		fileInfoMap = new TreeMap<String, String>();
		fileInfoMap.put("code", "426");
		fileInfoMap.put("message", "request inputstream parse error!");
		outputJson(client,response, out, 426, fileInfoMap);
		return;
	}else{
		if (debug){
			System.out.println("");
			System.out.println("file upload success,it will be verify and renamed and store!"); 
			System.out.println("");
			System.out.println(sb.toString()); 
		}
	}

	/**
	Iterator<Entry<String, String>> iter = fileInfoMap.entrySet().iterator();
	while (iter.hasNext()) {
		Entry<String, String> entry = iter.next();
		System.out.println(entry.getKey() + "=" + entry.getValue());
	}
	*/
	/** pic为上传控件的名称
	pic_content_type=text/plain
	pic_md5=b2be0c859ebe96cc085c3216e9cd47b5
	pic_name=新建文本文档.txt
	pic_path=/alidata/oss/tmp/0050528273
	pic_size=134
	*/

	//文件转存
	folder = folder + "/" + user_id + "/" + dir;
	domain = domain + "/" + user_id + "/" + dir;
	createFolder(folder);
	
	Pattern pattern;
	Matcher matcher;
	for (String inputControlName : inputControlNameList){
		String inputFileName = fileInfoMap.get(inputControlName + "_name");
		String fileExt = inputFileName.substring(inputFileName.lastIndexOf(".") + 1).toLowerCase();
		String fileName = getId();
		if (inputFileName.lastIndexOf(".") != -1) {
			fileName += "." + fileExt;
		}
		
		//检查扩展名
		if (!"*".equals(ext) && !"".equals(ext)){
			pattern = Pattern.compile("\\.("+ext+")$", Pattern.CASE_INSENSITIVE);
			matcher = pattern.matcher("." + fileExt);
			if (matcher.matches() == false) {
				fileInfoMap = new TreeMap<String, String>();
				fileInfoMap.put("code", "400");
				fileInfoMap.put("message", "file type error!");
				outputJson(client,response, out, 400, fileInfoMap);
				return;
			}
		}
		//检查文件大小
		if (Long.parseLong(fileInfoMap.get(inputControlName+"_size")) > maxSize) {
			fileInfoMap = new TreeMap<String, String>();
			fileInfoMap.put("code", "400");
			fileInfoMap.put("message", "file size error!");
			outputJson(client,response, out, 400, fileInfoMap);
			return;
		}
		//计算图片的大小和MD5值
		//计算图片缩放比例
		int imgWidth = 0;
		int imgHeight = 0;
		pattern = Pattern.compile("\\.(jpg|gif|bmp|png)$", Pattern.CASE_INSENSITIVE);
		matcher = pattern.matcher("." + fileExt);
		if (matcher.matches() && width > 0 && height > 0) {
			try {
				FileInputStream fis = new FileInputStream(fileInfoMap.get(inputControlName + "_path"));
				BufferedImage buff = ImageIO.read(fis);
				imgWidth = buff.getWidth();
				imgHeight = buff.getHeight();
				buff = null;
				fis.close();
				fis = null;
				if (width < imgWidth || height < imgHeight){
					fileInfoMap = new TreeMap<String, String>();
					fileInfoMap.put("code", "400");
					fileInfoMap.put("message", "file width or height error!");
					outputJson(client,response, out, 400, fileInfoMap);
					return;
				}		
			} catch (FileNotFoundException ex) {
			} catch (IOException ex) {
			}
		}
		System.out.println("");
		System.out.println("file verify success!"); 
		System.out.println("");
		
		moveFile(fileInfoMap.get(inputControlName + "_path"), folder + "/" + fileName);
		//fileInfoMap.put(inputControlName + "_path", folder + "/" + fileName);
		//返回完整带URL的地址
		fileInfoMap.put(inputControlName + "_path", domain + "/" + fileName);
	}
	fileInfoMap.put("code", "200");

	if (debug){
		System.out.println("");
		System.out.println("file renamed and store success!"); 
		System.out.println("");
		System.out.println(getJson(fileInfoMap)); 
	}

	outputJson(client,response, out, 200, fileInfoMap);

	//输出code为200时上传并转存成功，否则自动删除上传的文件:pic和yyy为input控件名称，yyy_size单位为字节
	/**
	{
	    "code": "200",
	    "pic_content_type": "text/plain",
	    "pic_md5": "6fb2b9dea54f6704d02bec0554f33e92",
	    "pic_name": "新建文本文档.txt",
	    "pic_path": domain + "/ad/201606051627040000010002973249.txt",
	    "pic_size": "1254"，	    
	    "yyy_content_type": "text/plain",
	    "yyy_md5": "6fb2b9dea54f6704d02bec0554f33e92",
	    "yyy_name": "新建文本文档.txt",
	    "yyy_path": domain + "/ad/201606051627040000010002973249.txt",
	    "yyy_size": "1254"
	}
	*/
%>
<%!
	private String getJson(TreeMap<String, String> fileInfoMap) {
		StringBuffer sb = new StringBuffer();
		sb.append("{");
		Iterator<Entry<String, String>> iter = fileInfoMap.entrySet().iterator();
		while (iter.hasNext()) {
			Entry<String, String> entry = iter.next();
			sb.append("\"" + entry.getKey().replace("\"", "\\\"") + "\"" + ":" + "\"" + entry.getValue().replace("\"", "\\\"") + "\"");
			if (iter.hasNext()) {
				sb.append(",");
			}
		}
		sb.append("}");
		return sb.toString();
	}

	private void outputJson(String client,HttpServletResponse response, JspWriter out, int status, TreeMap<String, String> fileInfoMap) {
		response.setStatus(status);
		if ("js".equals(client) == false){
			response.setContentType("application/json");
		}
		response.setHeader("Pragma", "No-cache");
		response.setHeader("Cache-Control", "no-cache");
		response.setDateHeader("Expires", 0);
		try {			
			if ("js".equals(client) == false){
				out.println(getJson(fileInfoMap));
			}else{
				out.println("<script>try{window.name=\""+getJson(fileInfoMap).replace("\"","\\\"")+"\";}catch(ex){}</script>");
			}
		} catch (Exception ex) {
			//json serialize error!
		}
	}

	private static String lastId = "";
	private static String uuid = "";

	/**
	 * 根据当前时间组合成一个30位的唯一字符串:year+month+day+hour+minute+second+000001+0+uuid(9位 )
	 * 
	 * @return yyyyMMddhhmmss000001+0+uuid(9位)
	 */
	private synchronized String getId() {
		String year = "";
		String month = "";
		String day = "";
		String hour = "";
		String minute = "";
		String second = "";
		Calendar calendar = Calendar.getInstance();
		switch (String.valueOf(calendar.get(Calendar.YEAR)).length()) {
			case 1 :
				year = "000" + String.valueOf(calendar.get(Calendar.YEAR));
				break;
			case 2 :
				year = "00" + String.valueOf(calendar.get(Calendar.YEAR));
				break;
			case 3 :
				year = "0" + String.valueOf(calendar.get(Calendar.YEAR));
				break;
			default :
				year = String.valueOf(calendar.get(Calendar.YEAR));
				break;
		}
		month = (String.valueOf(calendar.get(Calendar.MONTH)).length() == 1 && calendar.get(Calendar.MONTH) != 9) ? ("0" + String.valueOf(calendar.get(Calendar.MONTH) + 1)) : String.valueOf(calendar.get(Calendar.MONTH) + 1);
		day = (String.valueOf(calendar.get(Calendar.DATE)).length() == 1) ? ("0" + String.valueOf(calendar.get(Calendar.DATE))) : String.valueOf(calendar.get(Calendar.DATE));
		hour = (String.valueOf(calendar.get(Calendar.HOUR_OF_DAY)).length() == 1) ? ("0" + String.valueOf(calendar.get(Calendar.HOUR_OF_DAY))) : String.valueOf(calendar.get(Calendar.HOUR_OF_DAY));
		minute = (String.valueOf(calendar.get(Calendar.MINUTE)).length() == 1) ? ("0" + String.valueOf(calendar.get(Calendar.MINUTE))) : String.valueOf(calendar.get(Calendar.MINUTE));
		second = (String.valueOf(calendar.get(Calendar.SECOND)).length() == 1) ? ("0" + String.valueOf(calendar.get(Calendar.SECOND))) : String.valueOf(calendar.get(Calendar.SECOND));
		String id = year + month + day + hour + minute + second;
		if (lastId.length() == 0) {
			lastId = id + "000001";
		} else if (id.substring(0, 14).equals(lastId.substring(0, 14)) == false) {
			lastId = id + "000001";
		} else {
			if (lastId.length() != 20) {
				lastId = id + "000001";
			} else {
				int m = Integer.valueOf(lastId.substring(14)).intValue() + 1;
				for (int i = 0; i < 6 - String.valueOf(m).length(); i++) {
					id = id + "0";
				}
				lastId = id + m;
			}
		}

		// 每次都生成新的UUID，以免服务器时间来回修改导致主键重复
		uuid = "";

		if (uuid.equals("")) {
			uuid = String.valueOf(UUID.randomUUID().hashCode());
			if (uuid.startsWith("-")) {
				uuid = uuid.substring(1);
			}
			int len = uuid.length();
			if (len > 9) {
				uuid = uuid.substring(len - 9);
			}
			len = uuid.length();
			for (int i = 10; i > len; i--) {
				uuid = "0" + uuid;
			}
		}

		return lastId + uuid;
	}

	/**
	 * 文件转为字节数组
	 * 
	 * @param filePath
	 * @return
	 * @throws Exception
	 */
	private byte[] getBytesFromFile(String filePath) throws Exception {
		byte[] bytes = new byte[0];

		try {
			FileInputStream fis = new FileInputStream(filePath);
			ByteArrayOutputStream baos = new ByteArrayOutputStream(4096);

			byte[] bs = new byte[4096];
			int len;
			while ((len = fis.read(bs)) != -1) {
				baos.write(bs, 0, len);
			}
			bytes = baos.toByteArray();
			baos.close();
			baos = null;
			fis.close();
			fis = null;
		} catch (IOException ex) {
			throw new Exception("文件转为字节数组失败!", ex);
		}

		return bytes;
	}

	/**
	 * 创建文件
	 * 
	 * @param filePath
	 *            文件路径
	 * @param content
	 *            文件内容
	 * @throws Exception
	 */
	private void createFile(String filePath, String content) throws Exception {
		try {
			File file = new File(filePath);
			if (!file.exists()) {
				file.createNewFile();
			}

			FileWriter fw = new FileWriter(file);
			PrintWriter pw = new PrintWriter(fw);
			pw.println(content);
			pw.close();
			pw = null;
			fw.close();
			fw = null;
			file = null;
		} catch (Exception ex) {
			throw new Exception("创建文件失败!", ex);
		}
	}

	/**
	 * 创建文件
	 * 
	 * @param filePath
	 *            文件路径
	 * @param bytes
	 *            字节数组
	 * @throws Exception
	 */
	private void createFile(String filePath, byte[] bytes) throws Exception {
		try {
			File file = new File(filePath);
			if (!file.exists()) {
				file.createNewFile();
			}

			FileOutputStream fos = new FileOutputStream(file);
			fos.write(bytes);

			fos.close();
			fos = null;
			file = null;
		} catch (Exception ex) {
			throw new Exception("创建文件失败!", ex);
		}
	}

	/**
	 * 创建文件夹： 如果父文件夹不存在，将先创建父文件夹，再创建目标文件夹
	 * 
	 * @param folderPath
	 *            文件夹路径
	 * @throws Exception
	 */
	private void createFolder(String folderPath) throws Exception {
		try {
			File file = new File(folderPath);
			if (!file.isDirectory()) {
				file.mkdirs();
			}
			file = null;
		} catch (Exception ex) {
			throw new Exception("创建文件夹失败!", ex);
		}
	}

	/**
	 * 删除文件
	 * 
	 * @param filePath
	 *            文件路径
	 * @throws Exception
	 */
	private void deleteFile(String filePath) throws Exception {
		try {
			File file = new File(filePath);
			if (file.isFile()) {
				file.delete();
			}
			file = null;
		} catch (Exception ex) {
			throw new Exception("删除文件失败!", ex);
		}
	}

	/**
	 * 复制文件
	 * 
	 * @param fromFilePath
	 *            源文件路径
	 * @param toFilePath
	 *            目标文件路径
	 * @throws Exception
	 */
	private void copyFile(String fromFilePath, String toFilePath) throws Exception {
		try {
			createFile(toFilePath, getBytesFromFile(fromFilePath));
		} catch (Exception ex) {
			throw new Exception("复制文件失败!", ex);
		}
	}

	/**
	 * 移动文件
	 * 
	 * @param fromFilePath
	 *            源文件路径
	 * @param toFilePath
	 *            目标文件路径
	 * @throws Exception
	 */
	private void moveFile(String fromFilePath, String toFilePath) throws Exception {
		try {
			copyFile(fromFilePath, toFilePath);
			deleteFile(fromFilePath);
		} catch (Exception ex) {
			throw new Exception("移动文件失败!", ex);
		}
	}
%>
