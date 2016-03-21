//
//  InstagramAuthController.swift
//  InstagramDemo
//
//  Created by Jeff Lai on 3/20/16.
//  Copyright © 2016 Jeff Lai. All rights reserved.
//

import UIKit
import OAuthSwift

class InstagramAuthController : UIViewController {
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        let oauthswift = OAuth2Swift(
            consumerKey:    "4f428673cd4a4a0fbde11fca41a40ac1",
            consumerSecret: "ea4e4d66fbff4e3ea5fc4bc93edd6e20",
            authorizeUrl:   "https://api.instagram.com/oauth/authorize",
            responseType:   "token"
        )
        if let url = NSURL(string: "oauth-swift://oauth-callback/instagram") {
            oauthswift.authorizeWithCallbackURL(
                url,
                scope: "basic", state:"INSTAGRAM",
                success: { [weak self] credential, response, parameters in
                    if let strongSelf = self {
                        let photoCollectionController = PhotoCollectionController()
                        photoCollectionController.accessToken = credential.oauth_token
                        strongSelf.presentViewController(photoCollectionController, animated: true, completion: nil)
                    }
                },
                failure: { error in
                    print(error.localizedDescription)
                }
            )
        }
        
    }
    
}
