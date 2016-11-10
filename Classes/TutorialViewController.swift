//
//  ViewController.swift
//  UIPageViewController
//
//  Created by PJ Vea on 3/27/15.
//  Copyright (c) 2015 Vea Software. All rights reserved.
//

import UIKit

class TutorialViewController: UIViewController, UIPageViewControllerDataSource {

    @IBOutlet weak var homeButton: UIButton!
    var pageViewController: UIPageViewController!
    var pageTitles: NSArray!
    var pageImages: NSArray!
    var pageInfos: NSArray!
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        self.pageTitles = NSArray(objects: "¿QUE ES CONVERSA?", "¿PARA QUE PUEDE SERVIR?", "ENCUENTRA", "¿QUE ES UN ID?")
        
        self.pageImages = NSArray(objects: "Cam1", "Cam1", "Cam1", "Cam1")
        
        self.pageInfos = NSArray(objects: "Es como WhatsApp pero para que puedas chatear con empresas en tiempo real y GRATIS", "Consultar precios/disponibilidad de productos, información de lo que necesites, servicio al cliente, etc.", "Con quien necesites chatear buscando por el ID de la empresa o explora en las categorias", "El ID de una empresa es su nombre de usuario, ejemplo: '@tunegocio'. Puedes buscarlo con o sin el Arroba '@'.")

        self.pageViewController = self.storyboard?.instantiateViewController(withIdentifier: "PageViewController") as! UIPageViewController
        self.pageViewController.dataSource = self

        let startVC = self.viewControllerAtIndex(0) as ContentViewController
        let viewControllers = NSArray(object: startVC)
        
        self.pageViewController.setViewControllers(viewControllers as? [UIViewController], direction: .forward, animated: true, completion: nil)
        
        self.pageViewController.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.size.height)
        self.pageViewController.view.backgroundColor = UIColor(red: 0.22, green: 1.00, blue: 0.47, alpha: 1.0)
        
        self.addChildViewController(self.pageViewController)
        self.view.addSubview(self.pageViewController.view)
        self.pageViewController.didMove(toParentViewController: self)
        
        self.view.bringSubview(toFront: self.homeButton)
    }

    @IBAction func homeButtonPressed(_ sender: UIButton) {
        let vc = storyboard!.instantiateViewController(withIdentifier: "LoginView")
        self.present(vc, animated: true, completion: nil)
    }
    
    func viewControllerAtIndex(_ index: Int) -> ContentViewController
    {
        if ((self.pageTitles.count == 0) || (index >= self.pageTitles.count)) {
            return ContentViewController()
        }
        
        let vc: ContentViewController = self.storyboard?.instantiateViewController(withIdentifier: "ContentViewController") as! ContentViewController
        
        vc.imageFile = self.pageImages[index] as! String
        vc.titleText = self.pageTitles[index] as! String
        vc.infoText  = self.pageInfos[index] as! String
        vc.pageIndex = index
        
        return vc
    }
    
    // MARK: - Page View Controller Data Source
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController?
    {
        
        let vc = viewController as! ContentViewController
        var index = vc.pageIndex as Int
        
        
        if (index == 0 || index == NSNotFound)
        {
            return nil
        }
        
        index -= 1
        return self.viewControllerAtIndex(index)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        let vc = viewController as! ContentViewController
        var index = vc.pageIndex as Int
        
        if (index == NSNotFound)
        {
            return nil
        }
        
        index += 1
        
        if (index == self.pageTitles.count)
        {
            return nil
        }
        
        return self.viewControllerAtIndex(index)
  
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int
    {
        return self.pageTitles.count
    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int
    {
        return 0
    }
}

