AppsKit SPM


#1 基本思路：
设置好 最终需要数据结构, 所有字段都支持多语言。


import SwiftUI
import Combine

struct AppModel: Codable,Hashable {
    
  iconName,单纯名称，与 requesrBaseURL 构建云端获取icon的网址
  downloadURL, 下载安装地址
  
  根据国际语言代码： 组织 app名字 ，一句话简介, 这样来支持多语言
   
}


struct AppsModel: Codable,Hashable {
    
  Active:Bool = false 是否显示
  apps:[AppModel] app 列表
   
}

##1接口
requesrBaseURL: String = "https://xxx.com"
requestJsonName: String = "xxx.json"



##2

1、从远端获取 我所开发的app列表的 xxx.json 数据结构 AppsModel。
2、UI
根据提供的数据结构以及 获取当前app语言 进行渲染，根据提供的数据结构有跟app语言 对应，当然渲染该语言， 没有就默认英语，连英语都没有就选择数据结构里面第一个语言。

然后渲染成一个很精致的 app 列表。




##3 代码本地需求
import SwiftUI
import Foundation
import UIKit

extension String {
    var toLocalized: String {
        NSLocalizedString(self, bundle: Bundle.module, comment: "项目名称（首个字母大写）Kit localized string")
    }
}

代码中统一使用"key"toLocalized 进行 本地化，先要求中英文，以后适当时候在扩大支持范围。
            


##3公开接口

1、
AppsView(

requesrBaseURL: String = "https://xxx.com"
requestJsonName: String = "xxx.json"

){ Active in


返回  Active 让外部判断是否显示。


}

2、
public struct LocalizedInfo {


    public static var logo: UIImage {
        UIImage(named: "项目名称_logo", in: Bundle.module, with: nil) ?? UIImage()
    }


    public static var Name: String {
        "项目名称_title".toLocalized
    }

    public static var Description: String {
        "项目名称_description".toLocalized
    }
    
}


##Package.swift 要求

* 1、defaultLocalization: "en",
* 2、resources: [
                // Process the entire Resources directory.  This directive
                // bundles both localization and asset catalogs so they
                // can be accessed via Bundle.module.
                .process("Resources")
            ]
            
* 3、iOS 13 起声明：
    platforms: [
        .iOS(.v13)
    ]



