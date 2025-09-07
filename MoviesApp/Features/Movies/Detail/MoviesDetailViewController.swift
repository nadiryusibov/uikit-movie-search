//
//  MoviesDetailViewController.swift
//  MoviesApp
//
//  Created by Yusibov Nadir on 01.09.25.
//

import UIKit

class MoviesDetailViewController: UIViewController {
    
    private let movie: Movie
    private var isLoadingPlot = false

    private let scrolView = UIScrollView()
    
    private let contentStack:UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let posterView: UIImageView = {
        let posterView = UIImageView()
        posterView.contentMode = .scaleAspectFill
        posterView.image = UIImage(systemName: "photo")
        posterView.clipsToBounds = true
        posterView.layer.cornerRadius = 12
        posterView.translatesAutoresizingMaskIntoConstraints = false
        return posterView
        
    }()
    
    private let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        return titleLabel
    }()
    
    private let yearLabel: UILabel = {
        let yearLabel = UILabel()
        yearLabel.textColor = .white
        yearLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        yearLabel.backgroundColor = .systemBlue
        yearLabel.layer.cornerRadius = 6
        yearLabel.clipsToBounds = true
        yearLabel.translatesAutoresizingMaskIntoConstraints = false
        return yearLabel
    }()
    
    
    private let overViewTitleLabel: UILabel = {
        let overViewTitleLabel = UILabel()
        overViewTitleLabel.text = "Overview"
        overViewTitleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        overViewTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        return overViewTitleLabel
    }()
    
    private let overviewlabel: UILabel = {
        let overviewLabel = UILabel()
        overviewLabel.numberOfLines = 0
        overviewLabel.font = .systemFont(ofSize: 16)
        overviewLabel.translatesAutoresizingMaskIntoConstraints = false
        return overviewLabel
    }()
    
    private let favButton: UIButton = {
        let btn = UIButton(type: .system)
        if #available(iOS 15.0, *) {
            var cfg = UIButton.Configuration.filled()
            cfg.title = "Add to Favorites"
            cfg.baseBackgroundColor = .systemPink
            cfg.baseForegroundColor = .white
            btn.configuration = cfg
        }else{
            btn.setTitle("Ad to Favorites", for: .normal)
            btn.setTitleColor(.white, for: .normal)
            btn.backgroundColor = .systemPink
            btn.layer.cornerRadius = 10
            btn.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        }
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    
    private var isFavorite = false
    
    
    init(movie: Movie) {
        self.movie = movie
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let textView:UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.font = .systemFont(ofSize: 16)
        textView.textContainerInset = .init(top: 16, left: 16, bottom: 16, right: 16)
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.title = "Details"
        
        setupLayout()
        bindData()
        favButton.addTarget(self, action: #selector(favTapped), for: .touchUpInside)
        loadPlot()
    }
    
    
    private func loadPlot() {
        guard !isLoadingPlot else { return }
        isLoadingPlot = true
        overviewlabel.text = "Loading plot…"

        Task {
            do {
                let plot = try await APIClient.shared.fetchPlot(imdbID: movie.id)
                await MainActor.run {
                    self.overviewlabel.text = plot
                    self.isLoadingPlot = false
                }
            } catch {
                await MainActor.run {
                    self.overviewlabel.text = "Plot could not be loaded."
                    self.isLoadingPlot = false
                }
            }
        }
    }
    
    private func setupLayout(){
        scrolView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrolView)
        
        NSLayoutConstraint.activate([
            scrolView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrolView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrolView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrolView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Content Stack scroll un icine
        scrolView.addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrolView.contentLayoutGuide.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrolView.contentLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrolView.contentLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrolView.contentLayoutGuide.bottomAnchor, constant: -16),
            
            contentStack.widthAnchor.constraint(equalTo: scrolView.frameLayoutGuide.widthAnchor, constant: -32)
        ])
        
        // Posterin olcusu
        contentStack.addArrangedSubview(posterView)
        NSLayoutConstraint.activate([
            posterView.heightAnchor.constraint(equalToConstant: 220)
        ])
        contentStack.addArrangedSubview(titleLabel)
        
        contentStack.addArrangedSubview(yearLabel)
        contentStack.addArrangedSubview(overViewTitleLabel)
        contentStack.addArrangedSubview(overviewlabel)
        
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.heightAnchor.constraint(equalToConstant: 8).isActive = true
        contentStack.addArrangedSubview(spacer)
        contentStack.addArrangedSubview(favButton)
    }
    
    private func bindData() {
        titleLabel.text = movie.title
        yearLabel.text = "\(movie.year)"
        overviewlabel.text = movie.posterURL?.absoluteString
        updateFavoriteUI()
    }
    
    @objc private func favTapped() {
        isFavorite.toggle()
        updateFavoriteUI()
    }
    
    private func updateFavoriteUI() {
        if #available(iOS 15.0, *){
            var cfg = favButton.configuration ?? .filled()
            cfg.title = isFavorite ? "Added" : "Add to favorites"
            cfg.baseBackgroundColor = isFavorite ? .systemGreen : .systemPink
            favButton.configuration = cfg
        }else{
            favButton.setTitle(isFavorite ? "Added" : "Add to favorites", for: .normal)
            favButton.backgroundColor = isFavorite ? .systemGreen: .systemPink
        }
    }
    

}
