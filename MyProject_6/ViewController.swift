//
//  ViewController.swift
//  MyProject_6
//
//  Created by User on 22.12.20.
//

import UIKit
import FirebaseDatabase

class ViewController: UIViewController, ObserverDelegate {

    
    var notes:[NoteModel] = []
    
    lazy var createElement = CreateElement(view: self.view, viewControllerDelegate: delegate!, viewController: self)
    var delegate:ObserverDelegate?

//    var nodeArray:[UIView] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        // Do any additional setup after loading the view.
        //self.view.addSubview(dhfhhfhjdhf)
        addTap()
        loadData()
    }
    
    @objc func addNote(sender: UITapGestureRecognizer) {
        let touch = sender.location(in: self.view)
        let x = touch.x
        let y = touch.y
        let point = CGPoint(x: x, y: y)
        createElement.addNote(point: point, isNew: true, id: nil, text: "")
        
    }
    
    
    func addTap() {
        let newTap = UITapGestureRecognizer(target: self, action: #selector(addNote))
        newTap.numberOfTapsRequired = 2
        self.view.addGestureRecognizer(newTap)
        
    }
    
    func addToViewControllerArray(model: NoteModel) {
        notes.append(model)
        print(notes.count)
    }
    
    func loadData() {
        Database.database().reference().child("notes").observeSingleEvent(of: .value) { (snapshot) in
            for child in snapshot.children {
                let snap = child as! DataSnapshot
                let key = snap.key
                Database.database().reference().child("notes").child(key).observeSingleEvent(of: .value) { (noteSnapshot) in
                    var noteDictionary = [String:Any]()
                    for note in noteSnapshot.children {
                        let noteSnap = note as! DataSnapshot
                        let value = noteSnap.value!
                        let noteSnapName = noteSnap.key
                        noteDictionary[noteSnapName] = value
                    }
                    guard let x = noteDictionary["x"] as? CGFloat,
                          let y = noteDictionary["y"] as? CGFloat,
                          let text = noteDictionary["text"] as? String
                    else { return }
                    let point = CGPoint(x: x, y: y)
                    self.createElement.addNote(point: point, isNew: false, id: key, text: text)
                }
            }
            self.observeNewNote()
        }
    }
    
    func observeNewNote() {
    Database.database().reference().child("notes").observe(.childAdded) { (snapshot) in
            var isAdded = false
            for note in self.notes {
                if snapshot.key == note.id {
                    isAdded = true
                }
            }
        
    
        
            if !isAdded {
                
                let key = snapshot.key
                let value = snapshot.value as! [String:Any]
                
                guard let x = value["x"] as? CGFloat,
                      let y = value["y"] as? CGFloat,
                      let text = value["text"] as? String
                else { return }
                
                let point = CGPoint(x: x, y: y)

                self.createElement.addNote(point: point, isNew: false, id: key, text: text)
                //self.createElement.addNoteOnSuperView(with: value, key: key)
            }
        }
    }
}

extension ViewController:UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        for model in notes {
            if textView == model.textField {
                self.view.bringSubviewToFront(model.noteView!)
                UIView.animate(withDuration: 0.3) {
                    model.noteView?.frame.origin.y = 100
                    
                }
                Database.database().reference().child("notes").child(model.id!).updateChildValues(["y": 100])
                
            }
        }
        
//            note.moveNoteToVisiblePart(textViewTag: textView.tag)
    }
        
        func textViewDidChange(_ textView: UITextView) {
            for model in notes {
                if textView == model.textField {
                    if let text = textView.text, !text.isEmpty {
                        model.text = text
                        Database.database().reference().child("notes").child(model.id!).updateChildValues(["text": text])
                    } else {
                        model.text = ""
                        Database.database().reference().child("notes").child(model.id!).updateChildValues(["text": ""])
                    }
                }
            }
            //note.updateTextOnline(textViewTag: textView.tag)
        }

}

