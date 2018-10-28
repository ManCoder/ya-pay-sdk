/* The MIT License
 *
 * Copyright (c) 2017 NBCO Yandex.Money LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit

// MARK: - Styles
extension IconView {

    enum Styles {

        /// Tint style
        enum Tint {
            static let normal =
                Style(name: "IconView.tint.normal") { (view: IconView) in
                    view.imageView.tintColor = view.tintColor
                    view.backgroundColor = .clear
                }

            static let highlighted =
                normal +
                Style(name: "IconView.tint.highlighted") { (view: IconView) in
                    view.imageView.tintColor = view.tintColor.withAlphaComponent(0.5)
                }

            static let disabled =
                normal +
                Style(name: "IconView.tint.disabled") { (view: IconView) in
                    view.imageView.tintColor = .nobel
                }

            static let selected =
                normal +
                Style(name: "IconView.tint.selected") { (view: IconView) in
                    // TODO: IOS-1732
                }
        }

        /// FadeTint style
        enum FadeTint {
            static let normal =
                Style(name: "IconView.FadeTint.normal") { (view: IconView) in
                    view.imageView.tintColor = UIColor.fadeTint(from: view.tintColor)
                    view.backgroundColor = view.tintColor.withAlphaComponent(0.15)
                }

            static let highlighted =
                normal +
                Style(name: "IconView.FadeTint.highlighted") { (view: IconView) in
                    view.backgroundColor = view.tintColor.withAlphaComponent(0.08)
                }

            static let disabled =
                normal +
                Style(name: "IconView.FadeTint.disabled") { (view: IconView) in
                    view.imageView.tintColor = .nobel
                    view.backgroundColor = UIColor.nobel.withAlphaComponent(0.15)
                }
        }

        /// BackgoundTint style
        static let backgroundTint = Style(name: "IconView.backgroundTint") { (view: IconView) in
            view.imageView.tintColor = .inverse
            view.backgroundColor = view.tintColor
        }

        /// InverseBackgroundTint style
        enum InverseBackgroundTint {
            static let normal = UIView.Styles.shadow
                + Style(name: "IconView.InverseBackgroundTint.normal") { (view: IconView) in
                    view.imageView.tintColor = view.tintColor
                    view.backgroundColor = .inverse
                }

            static let highlighted =
                normal +
                Style(name: "IconView.InverseBackgroundTint.highlighted") { (view: IconView) in
                    view.backgroundColor = UIColor.inverse.withAlphaComponent(0.85)
                }

            static let disabled =
                normal +
                Style(name: "IconView.InverseBackgroundTint.disabled") { (view: IconView) in
                    view.imageView.tintColor = .nobel
                    view.backgroundColor = UIColor.inverse.withAlphaComponent(0.75)
                }
        }
    }
}
