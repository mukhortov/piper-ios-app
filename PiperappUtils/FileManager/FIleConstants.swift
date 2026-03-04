//
//  FIleConstants.swift
//  Piper
//
//  Created by Ihor Shevchuk on 2026-02-21.
//  Copyright © 2026 Ihor Shevchuk. All rights reserved.
//
import Foundation

extension FileManager {
    public enum Constants {
        private static let applicationGroupIdentifier = "group.pipertts.data"
        
        static var sharedFolder: URL? {
            return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Constants.applicationGroupIdentifier)
        }
        
        public static var modelURL: URL? {
            return sharedFolder?.appendingPathComponent(PiperAppUtils.Constants.modelFileNameWithExtension)
        }
        
        public static var jsonModelURL: URL? {
            return sharedFolder?.appendingPathComponent(PiperAppUtils.Constants.modelJSONFileNameWithExtension)
        }
    }
}
