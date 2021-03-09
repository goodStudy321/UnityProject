package Excel2Erl;

import org.apache.poi.hssf.usermodel.HSSFWorkbook;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

import java.io.*;
import java.util.HashMap;
import java.util.Map.Entry;
import java.util.ArrayList;

public class Excel2Erl {

    // lua文件导出路径
    private static String exportPath;
    // excel文件路径
    private static String importPath;
    //config文件路径
	private static String configPath;

	//php Config路径
    private static String phpConfigPath;

    //php 导出路径
	private static String phpExportPath;

    // 文件导入标记
    private static String importFileFlag;

    public static void main(String[] args) {
        // 初始化配置
        initConfig();
        // 遍历excel文件目录，导出Erl配置表
        listExcel2Erl();

        listExcel2PHP();
    }

    // 是否是excel文件
    public static boolean isExcelFile(String name) {
        if (null != name) {
            int Index = name.lastIndexOf(".");
            if(Index >= 0)
            {
            String fileType = name
                    .substring(name.lastIndexOf("."), name.length())
                    .trim().toLowerCase();
            return ".xls".equals(fileType) || ".xlsx".equals(fileType);
            }
            return false;
        }
        return false;
    }

    /**
     * 根据文件名获取excel对象
     */
    public static Workbook getWorkbook(String filename) {
        Workbook workbook = null;
        if (null != filename) {
            String fileType = filename
                    .substring(filename.lastIndexOf("."), filename.length())
                    .trim().toLowerCase();
            try {
                FileInputStream fileStream = new FileInputStream(new File(filename));
                if (".xls".equals(fileType)) {
                    workbook = new HSSFWorkbook(fileStream);
                } else if (".xlsx".equals(fileType)) {
                    workbook = new XSSFWorkbook(fileStream);
                }
            } catch (FileNotFoundException e) {
                throw new RuntimeException(filename + "，文件找不到。");
            } catch (IOException e) {
                throw new RuntimeException(filename + "，文件读取失败。");
            }
        }
        return workbook;
    }

    // 获取单元格的值
	public static String getCellValue(Cell cell, String type) {
		if (type.equals("int"))
		{
			return getCellNum(cell, type);
		}
		else {
			String value = "";
			try {
				value = cell.toString();
			}
			catch (NullPointerException e)
			{
				value = "";
			}
			if (value != "")
			{
				try{
					value = getCellNum(cell, type);
				}
				catch (Exception e) {
					return value;
				}
			}
			return value;
		}
	}

	public static String getCellNum(Cell cell, String type) {
    	if (type.equals("float")){
    		return cell.toString();
		}
		try{
			double num = cell.getNumericCellValue();
			int inum = (int) num;
			if ((num - inum) == 0) {
				return inum + "";
			}
			return Math.round(num) + "";}
		catch (Exception e) {
			String value = cell.toString();
			if (value.equals("") && type.equals("int")){
				return 0 + "";
			}else {
				return value;
			}
		}
	}

	public static boolean isCellEmpty(Cell cell){
		String value = cell.toString();
		return value == "";
	}
//        catch (Exception e) {
//            String value = cell.toString();
//			System.out.println("cell value：" + value);
//            // 插入文件内容
//            if (value.startsWith(importFileFlag)) {
//				System.out.println("test cell value：" + value);
//                String path = value.substring(value.indexOf(':') + 1);
//                File file = new File(path);
//                try {
//                    BufferedInputStream in = new BufferedInputStream(
//                            new FileInputStream(file));
//                    ByteArrayOutputStream out = new ByteArrayOutputStream();
//                    byte buff[] = new byte[2048];
//                    for (int len = 0; (len = in.read(buff)) != -1; ) {
//                        out.write(buff, 0, len);
//                    }
//                    in.close();
//                    out.close();
//                    // System.out.println(out.toString());
//                    return out.toString();
//                } catch (FileNotFoundException e1) {
//                    throw new RuntimeException("单元格（" + cell.getRowIndex()
//                            + "，" + cell.getColumnIndex() + "），\"" + path
//                            + "\"文件不存在。");
//                } catch (IOException e1) {
//                    throw new RuntimeException("单元格（" + cell.getRowIndex()
//                            + "，" + cell.getColumnIndex() + "），\"" + path
//                            + "\"文件读取失败。");
//                }
//            }
//            return value;
//        }
//    }

    private static void excel2Erl(File excelFile, File[] fileList) {
        String excelFileName = excelFile.getName().substring(0,
                excelFile.getName().lastIndexOf('.'));
        String excelPath = excelFile.getPath();
        String excelConfig = excelFileName + ".config";

        // 检查文件是否存在
        if (!excelFile.exists()) {
            throw new RuntimeException(excelPath + " ，文件不存在。");
        }
        // 查看对应的xxx.config存不存在
        boolean isConfigExist = false;
        for (File myFile : fileList) {
            if (excelConfig.equals(myFile.getName())) {
                isConfigExist = true;
            }
        }

        System.out.println(excelConfig + " is exist:" + isConfigExist);
        if (!isConfigExist) {
            return;
        }


        HashMap<String, String> erlConfig = initErlConfig(configPath + excelConfig);
        // 初始化导出目录
        File exportDir = new File(exportPath);

        // 创建目录
        if (!exportDir.exists()) {
            exportDir.mkdirs();
        }

        // excel表对象
        Workbook workbook = getWorkbook(excelPath);

        // 获取第1页的表格，索引从0开始
        Sheet sheet = workbook.getSheetAt(0);

        // 获取总行数
        int totalRow = sheet.getLastRowNum();
        System.out.println(excelFile.getName() + " 表格数量："
                + workbook.getNumberOfSheets() + " 表格名称："
                + sheet.getSheetName() + " 行数：" + sheet.getLastRowNum());

        // 第二行：描述
        // Row descRow = sheet.getRow(1);

        String outErl = erlConfig.get("out_name");
        String isList = erlConfig.get("is_list");
        String key = erlConfig.get("key");
        String value = erlConfig.get("value");
        Row keyRow = sheet.getRow(0);
        String[][] keyList = get_value(key, keyRow);
        String[][] valueList = get_value(value, keyRow);
        String fileName = exportPath + outErl + ".erl";

        try {
            FileOutputStream writerStream = new FileOutputStream(fileName);
            BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(writerStream, "UTF-8"));
            System.out.println("开始导出：" + outErl);
            writer.write("-module(" + outErl);
            writer.write(").\n" + "-include(\"config.hrl\").\n-export[find/1].\n");
            if(isList != null){writer.write("-compile({parse_transform, config_pt}).\n");}
            writer.write("?CFG_H\n\n");
            // 迭代每一行
            Row row = null;
            for (int i = 1; i <= totalRow; i++) {
                try {
                    row = sheet.getRow(i);
                    String keyOut = get_output(row, keyList, true, true);
                    String valueOut = get_output(row, valueList, false, true);
                    writer.write("?C(" + keyOut + ", " + valueOut + ")\n");
                }
				catch (IllegalStateException e) {
					System.out.println("key:" + get_output(row, keyList, true, true));
					throw new IllegalStateException(e);
				}
                catch (NullPointerException e)
                {}
            }
            writer.write("?CFG_E.");
            writer.close();
        } catch (IOException e) {
            throw new RuntimeException(fileName + "，文件导出失败。");
        }
        System.out.println("导出完成：" + outErl);
    }

    private static void listExcel2Erl() {
        File excelDir = new File(importPath);
        File configDir = new File(configPath);

        if (!excelDir.exists()) {
            throw new RuntimeException("excel文件目录不存在，请配置。");
        }
        File[] fileList = excelDir.listFiles();
        File[] configList = configDir.listFiles();
        System.out.println("test：" + fileList[1].getName());
        // 导出所有excel文件
        for (File file : fileList) {
            if (isExcelFile(file.getName())) {
                excel2Erl(file, configList);
            }
        }
    }

    private static void listExcel2PHP(){
		File excelDir = new File(importPath);
		File configDir = new File(phpConfigPath);

		if (!excelDir.exists()) {
			throw new RuntimeException("excel文件目录不存在，请配置。");
		}
		File[] fileList = excelDir.listFiles();
		File[] configList = configDir.listFiles();
		// 导出所有excel文件
		for (File file : fileList) {
			if (isExcelFile(file.getName())) {
				excel2PHP(file, configList);
			}
		}
	}

	private static void excel2PHP(File excelFile, File[] fileList) {
		String excelFileName = excelFile.getName().substring(0,
				excelFile.getName().lastIndexOf('.'));
		String excelPath = excelFile.getPath();
		String excelConfig = excelFileName + ".config";

		// 检查文件是否存在
		if (!excelFile.exists()) {
			throw new RuntimeException(excelPath + " ，文件不存在。");
		}
		// 查看对应的xxx.config存不存在
		boolean isConfigExist = false;
		for (File myFile : fileList) {
			if (excelConfig.equals(myFile.getName())) {
				isConfigExist = true;
			}
		}

		System.out.println(excelConfig + " is exist:" + isConfigExist);
		if (!isConfigExist) {
			return;
		}

		System.out.println("test：" + phpConfigPath + excelConfig);
		HashMap<String, String> erlConfig = initErlConfig(phpConfigPath + excelConfig);
		// 初始化导出目录
		File exportDir = new File(phpExportPath);

		// 创建目录
		if (!exportDir.exists()) {
			exportDir.mkdirs();
		}

		// excel表对象
		Workbook workbook = getWorkbook(excelPath);

		// 获取第1页的表格，索引从0开始
		Sheet sheet = workbook.getSheetAt(0);

		// 获取总行数
		int totalRow = sheet.getLastRowNum();
		System.out.println(excelFile.getName() + " 表格数量："
				+ workbook.getNumberOfSheets() + " 表格名称："
				+ sheet.getSheetName() + " 行数：" + sheet.getLastRowNum());

		// 第二行：描述
		// Row descRow = sheet.getRow(1);

		String outPHP = erlConfig.get("out_name");
		String key = erlConfig.get("key");
		String value = erlConfig.get("value");
		Row keyRow = sheet.getRow(0);
		String[][] keyList = get_value(key, keyRow);
		String[][] valueList = get_value(value, keyRow);
		String fileName = phpExportPath + outPHP + ".php";

		try {
			FileOutputStream writerStream = new FileOutputStream(fileName);
			BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(writerStream, "UTF-8"));
			System.out.println("开始导出：" + outPHP);
			// 迭代每一行
			Row row = null;
			for (int i = 1; i <= totalRow; i++) {
				try {
					row = sheet.getRow(i);
					String keyOut = get_output(row, keyList, true, false);
					String valueOut = get_output(row, valueList, false, false);
					writer.write( keyOut + "=" + valueOut + "||\n");
				}
				catch (IllegalStateException e) {
					System.out.println("key:" + get_output(row, keyList, true, false));
					throw new IllegalStateException(e);
				}
				catch (NullPointerException e)
				{}
			}
			writer.close();
		} catch (IOException e) {
			throw new RuntimeException(fileName + "，文件导出失败。");
		}
		System.out.println("导出完成：" + outPHP);
	}

    private static void initConfig() {
        File file = new File("./config.cfg");
        if (!file.exists()) {
            throw new RuntimeException("配置文件config.cfg不存在，初始化配置失败。");
        }

        HashMap<String, String> configMap = new HashMap<String, String>();
        try {
            BufferedReader in = new BufferedReader(new FileReader(file));

            System.out.println("初始化配置。");
            String line;
            while ((line = in.readLine()) != null) {
                if (line.contains("=")) {
                    String kv[] = line.split("=");
                    configMap.put(kv[0].trim(), kv[1].trim());
                }
            }
            in.close();

            importPath = configMap.get("importPath");
            exportPath = configMap.get("exportPath");
            configPath = configMap.get("configPath");
            phpConfigPath = configMap.get("phpConfigPath");
			phpExportPath = configMap.get("phpExportPath");
            importFileFlag = configMap.get("flag");

            for (Entry<String, String> entry : configMap.entrySet()) {
                System.out.println(entry.getKey() + " = " + entry.getValue());
            }
            System.out.println("配置初始化完成。");

        } catch (FileNotFoundException e) {
            throw new RuntimeException("配置文件config.cfg不存在，初始化配置失败。");
        } catch (IOException e) {
            throw new RuntimeException("读取配置文件config.cfg失败。");
        }
    }

    private static HashMap<String, String> initErlConfig(String fileString) {
        File file = new File(fileString);
        HashMap<String, String> erlConfig = new HashMap<String, String>();
        try {
            BufferedReader in = new BufferedReader(new FileReader(file));

            System.out.println("读取erlConfig配置。");
            String line;
            while ((line = in.readLine()) != null) {
                if (line.contains("=")) {
                    String kv[] = line.split("=");
                    String value = kv[1].trim();
                    erlConfig.put(kv[0].trim(), value);
                }
            }
            in.close();
            if (erlConfig.get("out_name") == null && erlConfig.get("key") == null &&
                    erlConfig.get("value") == null) {
                throw new RuntimeException("读取" + fileString + "erlConfig配置失败。关键key值为空");
            }

            for (Entry<String, String> entry : erlConfig.entrySet()) {
                System.out.println(entry.getKey() + " = " + entry.getValue());
            }
            System.out.println("erlConfig配置初始化完成。");
            return erlConfig;
        } catch (FileNotFoundException e) {
            throw new RuntimeException("配置文件config.cfg不存在，初始化配置失败。");
        } catch (IOException e) {
            throw new RuntimeException("读取配置文件config.cfg失败。");
        }
    }

    private static String[][] get_value(String value, Row keyRow) {
        String val[] = value.split(";");
        String list[][] = new String[val.length][2];
        for (int i = 0; i < val.length; i++){
            String val2[] = val[i].split(",");
            for(int j = 0; j < keyRow.getLastCellNum(); j++){
                if(getCellValue(keyRow.getCell(j), "string").equals(val2[0]))
                {
                	val2[0]=String.valueOf(j);
                	break;
                }
            }
            list[i] = val2;
        }
        return list;
    }

    private static String get_output(Row row, String[][] indexList, boolean IsKey, boolean IsErl) {
        ArrayList array = new ArrayList();
        for (String[] list : indexList) {
            // 没加,默认是int类型，list为list
            String type = "int";
            if(list.length > 1){type = list[1];}
            try {
                int i = Integer.valueOf(list[0]).intValue();
                Cell cell = row.getCell(i);
                String value = new String();
				if (IsKey && isCellEmpty(cell)){
					throw new NullPointerException("key值为空");
				}
				else if("null".equals(cell + "")) { // 内容为空时的处理
					value = get_default(type);
				}else{
                    value = get_value_by_type(getCellValue(cell, type), type);
                }
				array.add(value);
            }
			catch (NumberFormatException e){
				array.add(list[0]);
			}
			catch (IllegalStateException e) {
				System.out.println("有问题的列:" + list[0] + " 类型" + type);
				throw new IllegalStateException(e);
			}
        }
        int size = array.size();
        if (size > 1) {
            String output = "";
            for (int i = 0; i < size; i++) {
                if(i == size - 1){
                    output = output + array.get(i);
                }else
                {
					if (IsErl)
					{output = output + array.get(i) + ",";}
					else
					{output = output + array.get(i) + "%%";}
				}
            }
            if (IsErl)
            	{return "{" + output + "}";}
			else
				{return  output;}
			}
		else {
            return array.get(0).toString();
        }
    }

    private static String get_default(String type) {
        String value = new String();
        if (type.equals("int")){
            value = "0";
        }
        else if (type.equals("list")){
            value = "[]";
        }
        else if (type.equals("string")){
            value = "\"\"";
        }
        return value;
    }

    private static String get_value_by_type(String value, String type) {
        if (type.equals("list")){
            value = "[" + value + "]";
        }
        else if (type.equals("string")){
            value = "\"" + value + "\"";
        }
        return value;
    }
}
