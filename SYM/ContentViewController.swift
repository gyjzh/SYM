// The MIT License (MIT)
//
// Copyright (c) 2017 - 2018 zqqf16
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Cocoa

extension NSViewController {
    func windowController() -> MainWindowController? {
        return self.view.window?.windowController as? MainWindowController
    }
}

class ContentViewController: NSViewController {
    @IBOutlet var textView: NSTextView!

    var document: CrashDocument? {
        didSet {
            guard let document = document else {
                return
            }
            let font = self.textView.font
            self.textView.layoutManager?.replaceTextStorage(document.textStorage)
            self.textView.font = font
            self.updateCrashInfo()
            
            document.notificationCenter.addObserver(forName: .crashSymbolicated, object: nil, queue: nil) {  [weak self] (notification) in
                self?.updateCrashInfo()
            }
            document.notificationCenter.addObserver(forName: .crashDidOpen, object: nil, queue: nil) {  [weak self] (notification) in
                self?.updateCrashInfo()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupTextView()
    }

    private func setupTextView() {
        self.textView.font = NSFont(name: "Menlo", size: 11)
        self.textView.textContainerInset = CGSize(width: 10, height: 10)
        self.textView.allowsUndo = true
        self.textView.delegate = self
    }
    
    func textDidChange(_ notification: Notification) {
        self.updateCrashInfo()
    }
    
    func updateCrashInfo() {
        guard let document = self.document, let ranges = document.crashInfo?.executableBinaryBacktraceRanges() else {
            return
        }
        let textStorage = document.textStorage
        textStorage.beginEditing()
        textStorage.processHighlighting(ranges)
        textStorage.endEditing()
    }
}

extension ContentViewController: NSTextViewDelegate {
    func textView(_ view: NSTextView, menu: NSMenu, for event: NSEvent, at charIndex: Int) -> NSMenu? {
        let menu = NSMenu(title: "dSYM")
        let showItem = NSMenuItem(title: "Symbolicate", action: #selector(symbolicate), keyEquivalent: "")
        showItem.isEnabled = true
        menu.addItem(showItem)
        menu.allowsContextMenuPlugIns = true
        return menu
    }
    
    @objc func symbolicate(_ sender: AnyObject?) {
        self.windowController()?.symbolicate(sender)
    }
}

// Mark: Highlight
extension NSTextStorage {
    func processHighlighting(_ ranges:[NSRange]) {
        let attrs: [NSAttributedString.Key: AnyObject] = [
            .foregroundColor: NSColor(red:1.00, green:0.23, blue:0.18, alpha:1.0),
            .font: NSFontManager.shared.font(withFamily: "Menlo", traits: .boldFontMask, weight: 0, size: 11)!
        ]
        for range in ranges {
            self.setAttributes(attrs, range: range)
        }
    }
}
