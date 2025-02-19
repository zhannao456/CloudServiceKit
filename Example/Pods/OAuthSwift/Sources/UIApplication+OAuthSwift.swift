//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

#if os(iOS) || os(tvOS)
import UIKit

public extension UIApplication {
    @nonobjc
    internal static var topViewController: UIViewController? {
        #if !OAUTH_APP_EXTENSIONS
        return UIApplication.shared.topViewController
        #else
        return nil
        #endif
    }

    @available(iOS 13.0, tvOS 13.0, *)
    var connectedWindowScenes: [UIWindowScene] {
        self.connectedScenes.compactMap { $0 as? UIWindowScene }
    }

    @available(iOS 13.0, tvOS 13.0, *)
    var topWindowScene: UIWindowScene? {
        let scenes = connectedWindowScenes
        return scenes.filter { $0.activationState == .foregroundActive }.first ?? scenes.first
    }

    var topWindow: UIWindow? {
        if #available(iOS 13.0, tvOS 13.0, *) {
            return self.topWindowScene?.windows.first
        } else {
            return self.keyWindow
        }
    }

    internal var topViewController: UIViewController? {
        guard let rootController = self.topWindow?.rootViewController else {
            return nil
        }
        return UIViewController.topViewController(rootController)
    }
}

extension UIViewController {

    static func topViewController(_ viewController: UIViewController) -> UIViewController {
        guard let presentedViewController = viewController.presentedViewController else {
            return viewController
        }
        #if !topVCCastDisabled
        if let navigationController = presentedViewController as? UINavigationController {
            if let visibleViewController = navigationController.visibleViewController {
                return topViewController(visibleViewController)
            }
        } else if let tabBarController = presentedViewController as? UITabBarController {
            if let selectedViewController = tabBarController.selectedViewController {
                return topViewController(selectedViewController)
            }
        }
        #endif
        return topViewController(presentedViewController)
    }
}

#endif
