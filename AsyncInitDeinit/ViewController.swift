import UIKit

import PromiseKit

class ViewController: UIViewController {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var startButton: UIButton!
    
    var cancel: () -> () = {}
    var model: Model!
    
    override func viewDidLoad() {
        label.isHidden = true
        cancelButton.isHidden = true
    }

    @IBAction func cancel(sender: Any?) {
        cancel()
        label.isHidden = true
        cancelButton.isHidden = true
        startButton.isHidden = false
    }
    
    @IBAction func start(sender: Any?) {
        model = nil
        startButton.isHidden = true
        let _ = firstly { () -> Promise<Model> in
            self.label.isHidden = false
            self.label.text = "Loading A"
            self.cancelButton.isHidden = false
            return createAsync(cancel: &self.cancel).then { [unowned self] (a: A) -> Promise<Model> in
                self.label.text = "Loading B"
                return createAsync(cancel: &self.cancel).then { [unowned self] (b: B) -> Promise<Model> in
                    self.label.text = "Loading C"
                    return createAsync(cancel: &self.cancel).then { (c: C) -> Model in
                        self.label.isHidden = true
                        self.cancelButton.isHidden = true
                        self.startButton.isHidden = false
                        return Model(a: a, b: b, c: c)
                    }
                }
            }
        }
        .then { [unowned self] (model: Model) -> () in
            self.model = model
        }
    }

}

protocol DefaultConstructible {
    init()
}

class Thing: DefaultConstructible {

    required init() {
        print("Finished making \(type(of: self))")
    }

    deinit {
        print("Cleaning up \(type(of: self))")
    }
    
}

class A: Thing {}
class B: Thing {}
class C: Thing {}

func createAsync<T: DefaultConstructible>(cancel: inout () -> ()) -> Promise<T> {
    let (cancellationPromise, _, reject) = Promise<T>.pending()
    cancel = {
        reject(NSError.cancelledError())
    }
    return race(after(interval: 3).then { () -> T in return T() }, cancellationPromise)
}

class Model {

    var a: A
    var b: B
    var c: C
    
    init(a: A, b: B, c: C) {
        self.a = a
        self.b = b
        self.c = c
        print("Created Model")
    }
    
    deinit {
        print("Destroying Model")
    }

}
