    //
//  Translator.swift
//  SpeechRecognizerSample
//
//  Created by hirauchi.shinichi on 2016/09/12.
//  Copyright © 2016年 SAPPOROWORKS. All rights reserved.
//

import Foundation
import Alamofire

class Translator {

    fileprivate var accessToken = ""

    init() {

        // アクセストークン取得
        let clientId = "TranslationTwitterSample"
        let clientSecret = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

        let parameters:Parameters = [
            "client_id" : clientId,
            "client_secret" : clientSecret,
            "scope" : "http://api.microsofttranslator.com",
            "grant_type" : "client_credentials"
        ]
        let url = "https://datamarket.accesscontrol.windows.net/v2/OAuth2-13"
        Alamofire.request(url, method: .post, parameters: parameters).responseJSON { response in
            switch response.result {
            case .success(let value):
                if let json = value as? NSDictionary {
                    self.accessToken = json["access_token"] as! String
                }
            case .failure(let error):
                print(error)
            }
        }
    }

    func conversion(_ message:String, complate: @escaping (String) -> Void) {
        let query = message as NSString
        let encodeString = query.addingPercentEscapes(using: String.Encoding.utf8.rawValue)!
        let headers = [
            "Authorization": "Bearer \(accessToken)"
        ]
        let url = "http://api.microsofttranslator.com/v2/Http.svc/Translate?text=\(encodeString)&from=ja&to=en"
        Alamofire.request(url, method: .get, headers: headers).responseString { response in
            switch response.result {
            case .success(let value):
                let str:NSString  = value as NSString
                var array = str.components(separatedBy: NSCharacterSet(charactersIn: "<>") as CharacterSet)
                if array.count == 5 {
                    let result = array[2]
                    complate(result)
                }
                break
            case .failure(let error):
                complate(error.localizedDescription)
            }
        }
    }
}
