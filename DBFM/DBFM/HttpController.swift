//
//  File.swift
//  DBFM
//
//  Created by apple on 15/12/1.
//  Copyright © 2015年 pz1943. All rights reserved.
//

import UIKit
import SwiftyJSON
import Alamofire

protocol HttpProtocol {
    func didRecieveList(results: JSON)
    func didRecieveChannel(results: JSON)
}

class HttpController: NSObject {
    var delegate: HttpProtocol?
    
    func onSearchList(url: String, parameter: [String: AnyObject]?) {
        Alamofire.request(.GET, url, parameters: parameter).response { (request, resopnse, data, error) -> Void in
            let jsonResult = JSON(data: data!)
            self.delegate?.didRecieveList(jsonResult)
            }
//            .response { (_, _, data, _) -> Void in
//        }
    }
    
    func onSearchChannel(url: String) {
        Alamofire.request(.GET, url).response { (request, resopnse, data, error) -> Void in
            let jsonResult = JSON(data: data!)
            self.delegate?.didRecieveChannel(jsonResult)
            }
    }

    func downLoad(url: String) {
        
    }
}