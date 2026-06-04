"""
使用 Python 内置 msilib 创建 Choco GUI Windows 安装包 (.msi)
"""
import os
import sys
import msilib
from msilib import (
    Feature, CAB, Directory, Binary, Control, Dialog,
    RadioButtonGroup, ListBox, ComboBox, add_data, add_stream,
    make_id, sequence, text, UIText, create_record
)

APP_NAME = "Choco GUI"
APP_VERSION = "1.0.0"
MANUFACTURER = "Choco GUI Team"
UPGRADE_CODE = "{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}"
PRODUCT_CODE = "{B2C3D4E5-F6A7-8901-BCDE-F12345678901}"

def build_installer():
    """构建 MSI 安装包"""
    
    # 源文件目录
    source_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "app")
    output_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "ChocoGUI_Setup.msi")
    
    # 收集所有需要打包的文件
    files_to_package = []
    for root, dirs, filenames in os.walk(source_dir):
        for f in filenames:
            full_path = os.path.join(root, f)
            rel_path = os.path.relpath(full_path, source_dir)
            files_to_package.append((full_path, rel_path))
    
    print(f"找到 {len(files_to_package)} 个文件需要打包")
    
    # 创建 MSI 数据库
    db = msilib.init_database(
        output_path,
        msilib.MSIDBOPEN_CREATEDIRECT,
    )
    
    # 添加摘要信息
    db.CreatePropertyTable()
    add_data(db, "Property", [
        ("ProductName", APP_NAME),
        ("ProductVersion", APP_VERSION),
        ("Manufacturer", MANUFACTURER),
        ("ProductCode", PRODUCT_CODE),
        ("UpgradeCode", UPGRADE_CODE),
        ("ProductLanguage", "2052"),  # 中文简体
        ("ALLUSERS", "1"),
        ("ARPHELPLINK", "https://chocolatey.org"),
        ("ARPNOREPAIR", "1"),
        ("ARPNOMODIFY", "1"),
        ("WixUIRMOption", "UseRM"),
        ("MSIRESTARTMANAGERCONTROL", "Disable"),
        ("MSIDEPLOYMENTCOMPLIANT", "1"),
        ("REBOOT", "ReallySuppress"),
        ("LIMITUI", "1"),
        ("SecureCustomProperties", "WIX_DOWNGRADE_DETECTED;WIX_UPGRADE_DETECTED"),
    ])
    
    # 创建目录结构
    root_dir = Directory(db, "TARGETDIR", "SourceDir")
    program_files = Directory(db, "ProgramFilesFolder", ".")
    app_dir = Directory(db, "AppDir", APP_NAME, parent=program_files)
    
    # 创建开始菜单目录
    start_menu = Directory(db, "ProgramMenuFolder", ".")
    start_menu_dir = Directory(db, "StartMenuDir", APP_NAME, parent=start_menu)
    
    # 添加文件到安装目录
    # 先创建子目录
    sub_dirs = {}
    for full_path, rel_path in files_to_package:
        dir_part = os.path.dirname(rel_path)
        if dir_part and dir_part not in sub_dirs:
            dir_name = dir_part.replace(os.sep, "_")
            parent = app_dir
            # 处理嵌套目录
            parts = dir_part.split(os.sep)
            current = app_dir
            for i, part in enumerate(parts):
                key = os.sep.join(parts[:i+1])
                if key not in sub_dirs:
                    d = Directory(db, f"SubDir_{key.replace(os.sep, '_')}", part, parent=current)
                    sub_dirs[key] = d
                    current = d
                else:
                    current = sub_dirs[key]
    
    # 添加文件
    file_records = []
    for full_path, rel_path in files_to_package:
        dir_part = os.path.dirname(rel_path)
        parent_dir = sub_dirs.get(dir_part, app_dir) if dir_part else app_dir
        
        fname = os.path.basename(rel_path)
        file_id = rel_path.replace(os.sep, "_").replace(".", "_")
        
        try:
            add_data(db, "File", [
                (file_id, fname, file_id, 8192, 0, 0, None, 0)
            ])
        except:
            pass
        
        file_records.append((full_path, rel_path, parent_dir))
    
    # 创建 Component 表  
    add_data(db, "Component", [
        ("MainApp", "{C1D2E3F4-A5B6-7890-CDEF-123456789ABC}", "TARGETDIR", 2, None),
        ("AppDirComp", "{D2E3F4A5-B6C7-8901-DEFG-234567890BCD}", "AppDir", 2, None),
        ("ShortcutComp", "{E3F4A5B6-C7D8-9012-EFGH-34567890CDEF}", "StartMenuDir", 2, None),
    ])
    
    # 添加 Feature
    add_data(db, "Feature", [
        ("Complete", "Complete", "", 1, 1, 0, "", 0),
    ])
    
    add_data(db, "FeatureComponents", [
        ("Complete", "MainApp"),
        ("Complete", "AppDirComp"),
        ("Complete", "ShortcutComp"),
    ])
    
    # 添加 CAB 文件
    cab = CAB("choco_gui.cab")
    for full_path, rel_path, parent_dir in file_records:
        # 使用完整路径
        cab.add_file(full_path)
    
    # 将 CAB 嵌入 MSI
    product_name = db.get_property("ProductName")
    for full_path, rel_path, parent_dir in file_records:
        db.add_file(full_path, rel_path, parent_dir)
    
    # 创建快捷方式
    try:
        add_data(db, "Shortcut", [
            ("StartMenuShortcut", "AppDir", f"{APP_NAME}", None, 
             f"[AppDir]choco_gui.exe", None, None, 
             "Chocolatey 包管理器图形界面客户端"),
        ])
    except Exception as e:
        print(f"快捷方式创建警告: {e}")
    
    # 提交并保存
    db.Commit()
    db.Close()
    
    print(f"\nMSI 安装包已创建: {output_path}")
    print(f"文件大小: {os.path.getsize(output_path) / (1024*1024):.1f} MB")
    print("\n使用方式: 双击 ChocoGUI_Setup.msi 即可安装")
    
    return output_path

if __name__ == "__main__":
    build_installer()
