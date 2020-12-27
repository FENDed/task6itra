import UIKit

protocol ObserverDelegate {
    var notes:[NoteModel] { get set }
    func addToViewControllerArray(model: NoteModel)
}
