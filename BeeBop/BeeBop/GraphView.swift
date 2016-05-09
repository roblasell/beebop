//
//  GraphView.swift
//  BeeBop
//
//  Created by Ari Scourtas updated on 5/8/16.
//  Copyright © 2016 Tufts. All rights reserved.
//
//  Class that generates gradient graphs in UIViews.
//  Created under the guidance of:
// https://www.raywenderlich.com/13271/how-to-draw-graphs-with-core-plot-part-2

import UIKit

//use @IBDesignable to create custom view type that renders in Interface Builder
class GraphView: UIView {

    
    var graphPoints:[Double] = [1,2,3,4,5,6,7]
    var hitForceValues:[Double] = []
    var reactionTimeValues:[Double] = []
    var percentCorrectValues:[Double] = []
    
    var width:CGFloat = 0
    var height:CGFloat = 0
    let margin:CGFloat = 20.0
    var rectangle:CGRect = CGRectNull

    //1 - the properties for the gradient
    @IBInspectable var startColor: UIColor = UIColor.redColor()
    @IBInspectable var endColor: UIColor = UIColor.greenColor()

    //override drawRect in order to draw the UIView as a graph
    override func drawRect(rect: CGRect) {
        
        //set dimensions of graph background
        var startPoint:CGPoint = CGPoint.zero
        var endPoint:CGPoint = CGPoint(x:0, y:0)
        
        if(accessibilityIdentifier == "hitForceUIView"){
            graphPoints = hitForceValues
        } else if (accessibilityIdentifier == "reactionTimeUIView"){
            graphPoints = reactionTimeValues
        } else if (accessibilityIdentifier == "percentCorrectUIView"){
            graphPoints = percentCorrectValues
        } else{
            print("Error: additional GraphViews must be assigned an accessibilityIdentifier")
        }
        
        
        width = rect.width
        height = rect.height

        //set up background clipping area to trim corners to be round
        let path = UIBezierPath(roundedRect: rect,
                                byRoundingCorners: UIRectCorner.AllCorners,
                                cornerRadii: CGSize(width: 8.0, height: 8.0))
        path.addClip()
        
        //get the current context
        let context = UIGraphicsGetCurrentContext()
        let colors = [startColor.CGColor, endColor.CGColor]
        
        //set up the color space
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        //set up the color stops
        let colorLocations:[CGFloat] = [0.0, 1.0]
        
        //set up the gradient
       let gradient = CGGradientCreateWithColors(colorSpace,
                                                  colors,
                                                  colorLocations)!
        
                //actually draw the gradient
        endPoint = CGPoint(x:0, y:self.bounds.height)
        CGContextDrawLinearGradient(context,
                                    gradient,
                                    startPoint,
                                    endPoint,
                                CGGradientDrawingOptions.DrawsAfterEndLocation)


       //here down is the stuff that draws the points
        let columnXPoint = { (column:Double) -> CGFloat in
            //Calculate gap between points
            let spacer = (self.width - self.margin*2 - 4) /
                CGFloat((self.graphPoints.count - 1))
            var x:CGFloat = CGFloat(column) * spacer
            x += self.margin + 2
            return x
        }
        let topBorder:CGFloat = 60
        let bottomBorder:CGFloat = 50
        let graphHeight = height - topBorder - bottomBorder
        let maxValue = graphPoints.maxElement()
        let columnYPoint = { (graphPoint:Double) -> CGFloat in
            var y:CGFloat = CGFloat(graphPoint) /
                CGFloat(maxValue!) * graphHeight
            y = graphHeight + topBorder - y // Flip the graph
            return y
        }
        
        // draw the line graph
        
        UIColor.whiteColor().setFill()
        UIColor.whiteColor().setStroke()
        
        //set up the points line
        let graphPath = UIBezierPath()
        //go to start of line
        graphPath.moveToPoint(CGPoint(x:columnXPoint(0),
            y:columnYPoint(graphPoints[0])))
        
        //add points for each item in the graphPoints array
        //at the correct (x, y) for the point
        for i in 1..<graphPoints.count {
            let j = Double(i)
            let nextPoint = CGPoint(x:columnXPoint(j),
                                    y:columnYPoint(graphPoints[i]))
            graphPath.addLineToPoint(nextPoint)
        }
        
        //Create the clipping path for the graph gradient
        
        //1 - save the state of the context (commented out for now)
        CGContextSaveGState(context)
        
        //2 - make a copy of the path
        let clippingPath = graphPath.copy() as! UIBezierPath
        
        //3 - add lines to the copied path to complete the clip area
        
        let count = Double(graphPoints.count - 1)
        clippingPath.addLineToPoint(CGPoint(
            x: columnXPoint(count),
            y:height))
        clippingPath.addLineToPoint(CGPoint(
            x:columnXPoint(0),
            y:height))
        clippingPath.closePath()
        
        //4 - add the clipping path to the context
        clippingPath.addClip()
        
        //Second gradient under line
        let highestYPoint = columnYPoint(maxValue!)
        startPoint = CGPoint(x:margin, y: highestYPoint)
        endPoint = CGPoint(x:margin, y:self.bounds.height)
        CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, CGGradientDrawingOptions.DrawsAfterEndLocation)
        
        CGContextRestoreGState(context)
        
        //Draw line
        graphPath.lineWidth = 2.0
        graphPath.stroke()
        
        //Add discrete points
        for i in 0..<graphPoints.count {
            let j = Double(i)
            var point = CGPoint(x:columnXPoint(j), y:columnYPoint(graphPoints[i]))
            point.x -= 5.0/2
            point.y -= 5.0/2
            
            let circle = UIBezierPath(ovalInRect:
                CGRect(origin: point,
                    size: CGSize(width: 5.0, height: 5.0)))
            circle.fill()
        }
        
        //Draw horizontal graph lines on the top of everything
        let linePath = UIBezierPath()
        
        //top line
        linePath.moveToPoint(CGPoint(x:margin, y: topBorder))
        linePath.addLineToPoint(CGPoint(x: width - margin,
            y:topBorder))
        
        //center line
        linePath.moveToPoint(CGPoint(x:margin,
            y: graphHeight/2 + topBorder))
        linePath.addLineToPoint(CGPoint(x:width - margin,
            y:graphHeight/2 + topBorder))
        
        //bottom line
        linePath.moveToPoint(CGPoint(x:margin,
            y:height - bottomBorder))
        linePath.addLineToPoint(CGPoint(x:width - margin,
            y:height - bottomBorder))
        let color = UIColor(white: 1.0, alpha: 0.3)
        color.setStroke()
        
        linePath.lineWidth = 1.0
        linePath.stroke()
    }

    
    func setHitForce(hitForce:[Double]){
        hitForceValues = hitForce
    }
    
    func setReactionTime(reactionTime:[Double]){
        reactionTimeValues = reactionTime
    }
    
    func setPercentCorrect(percentCorrect:[Double]){
        percentCorrectValues = percentCorrect
    }
    
    //reload the views when switching via segmented control
    func redisplayView(){
        self.setNeedsDisplay()
    }
 
}
