//
//  StageViewController.swift
//  JobTracker
//
//  Created by Joanne Dyer on 2/20/15.
//  Copyright (c) 2015 Joanne Maynard. All rights reserved.
//

import Foundation

protocol StageSelectionDelegate {
    func stageSelected(newStage: Stage, isPrevious: Bool)
}

class StageViewController: UIViewController {
    
    @IBOutlet weak var buttonOne: UIButton!
    @IBOutlet weak var buttonTwo: UIButton!
    @IBOutlet weak var buttonThree: UIButton!
    @IBOutlet weak var buttonFour: UIButton!
    @IBOutlet weak var buttonFive: UIButton!
    
    var delegate: StageSelectionDelegate!
    var loadedBasic: JobBasic!
    
    var buttonStageArray = [(Stage, String)]()
    var lastItemIsPreviousStage = true
    var heightConstraint: NSLayoutConstraint!
    var positionStringsFromNumbers: [Int: String]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        positionStringsFromNumbers = [1: "First", 2: "Second", 3: "Third", 4: "Fourth", 5: "Fifth", 6: "Sixth", 7: "Seventh", 8: "Eighth", 9: "Ninth", 10: "Tenth"]
        
        view.autoresizingMask = UIViewAutoresizing.FlexibleWidth
        
        heightConstraint = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1.0, constant: 198)
        view.addConstraint(heightConstraint)

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        updateButtons()
        updateConstraints()
    }
    
    func updateButtons() {
        let buttonArray = [buttonOne, buttonTwo, buttonThree, buttonFour, buttonFive]
        
        //buttons are set from bottom to top
        let currentStage = Stage(rawValue: loadedBasic.stage.integerValue)!
        let interviewNumber = loadedBasic.highestInterviewNumber
        let details = loadedBasic.details
        lastItemIsPreviousStage = true
        switch currentStage {
        case .Potential:
            buttonStageArray = [(Stage.Rejected, Stage.Rejected.title), (Stage.Offer, Stage.Offer.title), (Stage.Decision, Stage.Decision.title), (Stage.Interview, Stage.Interview.title), (Stage.Applied, Stage.Applied.title)]
            lastItemIsPreviousStage = false
        case .Applied:
            buttonStageArray = [(Stage.Rejected, Stage.Rejected.title), (Stage.Offer, Stage.Offer.title), (Stage.Decision, Stage.Decision.title), (Stage.Interview, Stage.Interview.title), (Stage.Potential, "Return to \(Stage.Potential.title)")]
        case .Interview:
            buttonStageArray = [(Stage.Rejected, Stage.Rejected.title), (Stage.Offer, Stage.Offer.title), (Stage.Decision, Stage.Decision.title)]
            if interviewNumber!.integerValue < 10 { //max of ten interview stages
                buttonStageArray += [(Stage.Interview, "\(positionStringsFromNumbers[(interviewNumber!.integerValue + 1)]!) Interview Arranged")]
            }
            
            if interviewNumber!.integerValue != 1 {
                buttonStageArray += [(Stage.Interview, "Return to \(positionStringsFromNumbers[(interviewNumber!.integerValue - 1)]!) Interview Arranged")]
            } else if details.appliedStarted {
                buttonStageArray += [(Stage.Applied, "Return to \(Stage.Applied.title)")]
            } else {
                buttonStageArray += [(Stage.Potential, "Return to \(Stage.Potential.title)")]
            }
        case .Decision:
            buttonStageArray = [(Stage.Rejected, Stage.Rejected.title), (Stage.Offer, Stage.Offer.title)]
            if details.interviewStarted {
                if interviewNumber! == 1 {
                    buttonStageArray += [(Stage.Interview, "Return to \(Stage.Interview.title)")]
                } else {
                    buttonStageArray += [(Stage.Interview, "Return to \(positionStringsFromNumbers[(interviewNumber!.integerValue)]!) Interview Arranged")]
                }
            } else if details.appliedStarted {
                buttonStageArray += [(Stage.Applied, "Return to \(Stage.Applied.title)")]
            } else {
                buttonStageArray += [(Stage.Potential, "Return to \(Stage.Potential.title)")]
            }
        case .Offer:
            buttonStageArray = [(Stage.Rejected, Stage.Rejected.title)]
            if details.decisionStarted {
                buttonStageArray += [(Stage.Decision, "Return to \(Stage.Decision.title)")]
            } else if details.interviewStarted {
                if interviewNumber! == 1 {
                    buttonStageArray += [(Stage.Interview, "Return to \(Stage.Interview.title)")]
                } else {
                    buttonStageArray += [(Stage.Interview, "Return to \(positionStringsFromNumbers[(interviewNumber!.integerValue)]!) Interview Arranged")]
                }
            } else if details.appliedStarted {
                buttonStageArray += [(Stage.Applied, "Return to \(Stage.Applied.title)")]
            } else {
                buttonStageArray += [(Stage.Potential, "Return to \(Stage.Potential.title)")]
            }
        case .Rejected:
            if details.offerStarted {
                buttonStageArray = [(Stage.Offer, "Return to \(Stage.Offer.title)")]
            } else if details.decisionStarted {
                buttonStageArray = [(Stage.Decision, "Return to \(Stage.Decision.title)")]
            } else if details.interviewStarted {
                if interviewNumber! == 1 {
                    buttonStageArray = [(Stage.Interview, "Return to \(Stage.Interview.title)")]
                } else {
                    buttonStageArray = [(Stage.Interview, "Return to \(positionStringsFromNumbers[(interviewNumber!.integerValue)]! ) Interview Arranged")]
                }
            } else if details.appliedStarted {
                buttonStageArray = [(Stage.Applied, "Return to \(Stage.Applied.title)")]
            } else {
                buttonStageArray = [(Stage.Potential, "Return to \(Stage.Potential.title)")]
            }
        }
        
        //set used buttons
        for i in 0..<buttonStageArray.count {
            buttonArray[i].setTitle(buttonStageArray[i].1, forState: UIControlState.Normal)
            buttonArray[i].hidden = false
            buttonArray[i].setTitleColor(UIColor.blueColor(), forState: UIControlState.Normal)
        }
        
        //hide unused buttons
        for i in buttonStageArray.count..<5 {
            buttonArray[i].hidden = true
        }
        
        //change the color of the previous stage button
        if lastItemIsPreviousStage {
            buttonArray[buttonStageArray.count - 1].setTitleColor(UIColor.redColor(), forState: UIControlState.Normal)
        }
    }
    
    @IBAction func stageClicked(sender: UIButton) {
        let tag = sender.tag
        let stage = buttonStageArray[tag].0
        var isPrevious = false
        if tag == buttonStageArray.count - 1 && lastItemIsPreviousStage {
            isPrevious = true
        }
        
        delegate.stageSelected(stage, isPrevious: isPrevious)
    }
    
    func updateConstraints() {
        let height = CGFloat(8 + (buttonStageArray.count * 38))
        heightConstraint.constant = height
    }
    
    //TODO add second view with one less line
}
