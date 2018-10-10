//
//  ChartPageViewController.swift
//  ConversaManager
//
//  Created by Edgar Gomez on 3/30/17.
//  Copyright © 2017 Conversa. All rights reserved.
//

import UIKit

class ChartPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    var pages = [ChartViewController]()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.delegate = self
        self.dataSource = self

        let pageControl = UIPageControl.appearance(whenContainedInInstancesOf: [ChartPageViewController.self])

        pageControl.pageIndicatorTintColor = UIColor(red: 158.0/255.0, green: 124.0/255.0, blue: 217.0/255.0, alpha: 0.4)

        pageControl.currentPageIndicatorTintColor = UIColor(red: 158.0/255.0, green: 124.0/255.0, blue: 217.0/255.0, alpha: 1.0)
    }

    @objc func loadCharts(data: Dictionary<String, Any>) {
        if pages.count > 0 {
            pages.removeAll()
        }

        for (_, chartData) in data {
            if let info = chartData as? Dictionary<String, AnyObject> {
                let type = info["type"] as? String ?? ""
                let title = info["title"] as? String ?? ""
                let innerData = info["data"] as? [String:Any] ?? [:]

                if type.isEmpty {
                    continue
                }

                let page = storyboard?.instantiateViewController(withIdentifier: "ChartViewController") as! ChartViewController
                page.loadViewIfNeeded()

                switch type {
                case "pie":
                    page.createChart(with: .PieType, title:title, data: innerData)
                case "line":
                    page.createChart(with: .LineType, title:title, data: innerData)
                case "bar":
                    page.createChart(with: .BarType, title:title, data: innerData)
                case "radar":
                    page.createChart(with: .RadarType, title:title, data: innerData)
                default:
                    continue
                }

                pages.append(page)
            }
        }

        if pages.count > 0 {
            setViewControllers([pages.first!],
                               direction: UIPageViewController.NavigationDirection.forward,
                               animated: false,
                               completion: nil)
        }
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        var currentIndex = pages.index(of: viewController as! ChartViewController)!

        if currentIndex == NSNotFound {
            return nil
        }

        currentIndex += 1

        if currentIndex == pages.count {
            return nil
        }

        return pages[currentIndex]
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        var currentIndex = pages.index(of: viewController as! ChartViewController)!

        if currentIndex == 0 || currentIndex == NSNotFound {
            return nil
        }

        currentIndex -= 1

        if currentIndex == pages.count {
            return nil
        }

        return pages[currentIndex]
    }

    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return pages.count
    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0
    }

}
