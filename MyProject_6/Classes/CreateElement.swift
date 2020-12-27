import UIKit
import FirebaseDatabase

class CreateElement {
    
    private let view:UIView
    private let viewController:UIViewController
    private var viewControllerDelegate:ObserverDelegate
    
    
    let dataBase = Database.database().reference()
    
    init(view: UIView,viewControllerDelegate: ObserverDelegate, viewController:UIViewController) {
        self.view = view
        self.viewControllerDelegate = viewControllerDelegate
        self.viewController = viewController
    }
    
    func addNote(point: CGPoint, isNew:Bool, id:String?, text:String) {
        let noteModel = NoteModel()

        
        let newNote = UIView()
        
        noteModel.noteView = newNote
        
        let squareWidth:CGFloat = self.view.frame.size.width / 2
        let squareHeight:CGFloat = self.view.frame.size.height / 2
        newNote.isUserInteractionEnabled = true
        newNote.frame = CGRect(x: point.x, y:  point.y, width: squareWidth, height: squareWidth)
        newNote.backgroundColor = UIColor(red: 225/255.0, green: 255/255.0, blue: 255/255.0, alpha: 1)
//        newNote.clipsToBounds = true
        newNote.layer.borderWidth = 1
        newNote.layer.borderColor = UIColor.black.cgColor
        view.addSubview(newNote)
        viewControllerDelegate.addToViewControllerArray(model: noteModel)
        addTap(noteView: noteModel)
        addTopContainer(noteView: noteModel)
        addInNote(noteModel)
        
        noteModel.textField!.text = text
        
        
        if isNew {
            createId(noteModel: noteModel)
            saveOnDB(noteModel: noteModel)
        
        }else {
            guard let id = id else { return }
            noteModel.id = id
        }
        
        observeChanges(of: noteModel)
        observeDeletion()
    }
    
    private func observeChanges(of model: NoteModel) {
        Database.database().reference().child("notes").child(model.id!).observe(.childChanged) { (noteSnapshot) in
                let value = [noteSnapshot.key : noteSnapshot.value]
                self.updateView(model, key: model.id!, value: value as [String:Any])
            }
        
    }
    
    private func observeDeletion() {
            Database.database().reference().child("notes").observe(.childRemoved) { (noteSnapshot) in
                let key = noteSnapshot.key
                var index = 0
                for note in self.viewControllerDelegate.notes {
                    if key == note.id {
                        note.noteView!.removeFromSuperview()
                        self.viewControllerDelegate.notes.remove(at: index)
                        self.dataBase.child("notes").child(note.id!).removeValue()
                    }
                    index += 1
                }
            }
        }
    
    func updateView(_ model: NoteModel, key: String, value: [String:Any]) {
            guard let noteView = model.noteView else {
                return
            }
            noteView.bringSubviewToFront(noteView)
            
            if let value = value["x"] as? CGFloat {
                noteView.frame.origin.x = value
            }
            if let value = value["y"] as? CGFloat {
                noteView.frame.origin.y = value
            }
            
            if let value = value["text"] as? String {
                model.textField!.text = value
            }
        }
    
    private func addInNote(_ noteModel:NoteModel ) {
        guard let noteView = noteModel.noteView else { return }
        let newField = UITextView()
        
        noteModel.textField = newField
        newField.addDoneButtonOnKeyboard()
        newField.backgroundColor = .gray
        newField.textColor = .white
        newField.font = .boldSystemFont(ofSize: 14)
        newField.frame = CGRect(x: noteView.bounds.origin.x, y: 20, width: noteView.bounds.size.width, height: noteView.bounds.size.height - 20)
        
        
        noteView.addSubview(newField)
        newField.delegate = viewController as! UITextViewDelegate
    }
    
    func saveOnDB(noteModel:NoteModel) {
        //createId(noteModel: noteModel)
        
        guard let noteView = noteModel.noteView else { return }
        
        let note:[String:Any] = [
            "x": noteView.frame.origin.x as NSObject,
            "y": noteView.frame.origin.y as NSObject,
            "text": "" as NSObject
            //"fontSize": 12 as NSObject
        ]
        
        guard let id = noteModel.id else { return }
        
        if viewControllerDelegate.notes.count == 0 {
            let noteDict = [String:Any]()
            dataBase.child("notes").setValue(noteDict)
            dataBase.child("notes").child(id).setValue(note)
        }else {
            dataBase.child("notes").child(id).setValue(note)
        }
        
        
    }
    
    func createId(noteModel:NoteModel) {
        let uuid = UUID().uuidString
        noteModel.id = uuid
    }
    
    @objc func moveNote(sender:UIPanGestureRecognizer) {
        guard let senderView = sender.view else {
            print("hello")
            return
        }
        
        let point = sender.location(in: view)
        senderView.center = point
        self.view.bringSubviewToFront(senderView)

        
        for note in viewControllerDelegate.notes {
            if senderView == note.noteView! {
                dataBase.child("notes").child(note.id!).updateChildValues(["x": note.noteView?.frame.origin.x, "y": note.noteView?.frame.origin.y])
            }
        }
    }
    
    
    
    func addTap(noteView:NoteModel) {
        guard let view = noteView.noteView else { return }
        
        let newTap = UIPanGestureRecognizer(target: self, action: #selector(moveNote))
        view.addGestureRecognizer(newTap)
    }
    
    func addTopContainer(noteView:NoteModel) {
        let topContainer = UIView()
        
        guard let nView = noteView.noteView else { return }
        
        
        
        topContainer.backgroundColor = .black
        topContainer.translatesAutoresizingMaskIntoConstraints  = false
        nView.addSubview(topContainer)
        noteView.topContainer = topContainer
        NSLayoutConstraint(item: topContainer, attribute: .top, relatedBy: .equal, toItem: nView, attribute: .top, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: topContainer, attribute: .trailing, relatedBy: .equal, toItem: nView, attribute: .trailing, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: topContainer, attribute: .leading, relatedBy: .equal, toItem: nView, attribute: .leading, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: topContainer, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 20).isActive = true
        addDeleteBtn(noteView)
    }
    	
    func addDeleteBtn(_ topContainer:NoteModel) {
        let deleteBtn = UIView()
        topContainer.deleteBtn = deleteBtn
        deleteBtn.backgroundColor = .red
        deleteBtn.isUserInteractionEnabled = true
        deleteBtn.translatesAutoresizingMaskIntoConstraints = false
        
        guard let topContainer = topContainer.topContainer else { return }
        
        topContainer.addSubview(deleteBtn)
        print(deleteBtn.isDescendant(of: topContainer))
        NSLayoutConstraint(item: deleteBtn, attribute: .top, relatedBy: .equal, toItem: topContainer, attribute: .top, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: deleteBtn, attribute: .trailing, relatedBy: .equal, toItem: topContainer, attribute: .trailing, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: deleteBtn, attribute: .bottom, relatedBy: .equal, toItem: topContainer, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: deleteBtn, attribute: .height, relatedBy: .equal, toItem: deleteBtn, attribute: .width, multiplier: 1, constant: 0).isActive = true
        
        addDeleteTap(deleteBtn)
    }
    
    func addDeleteTap(_ deleteBtn:UIView) {
        let newTap = UITapGestureRecognizer(target: self, action: #selector(deleteNote))
        deleteBtn.addGestureRecognizer(newTap)
    }

    @objc func deleteNote(sender:UITapGestureRecognizer) {
        guard let senderView = sender.view else {
            return
        }
        var index = 0
        for element in viewControllerDelegate.notes {
            if senderView.isDescendant(of: element.topContainer!) {
                element.noteView!.removeFromSuperview()
                viewControllerDelegate.notes.remove(at: index)
                dataBase.child("notes").child(element.id!).removeValue()
            }
            index += 1
        }
    }
}


