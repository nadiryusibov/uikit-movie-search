//
//  MovieCellTableViewCell.swift
//  MoviesApp
//
//  Created by Yusibov Nadir on 01.09.25.
//

import UIKit

final class MovieCell: UITableViewCell {
    
    static let reuseId = "MovieCell"
    
    // url den yuklenilecek burdaaa
    
    
    private let posterView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "photo")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemBlue
        imageView.backgroundColor = .systemGray6
        imageView.layer.cornerRadius = 5
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let yearLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var imageTask: Task<Void, Never>?
    
    override init (style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError( "init(coder:) has not been implemented" )
    }
    
    private func setupUI() {
        contentView.addSubview(posterView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(yearLabel)
        
        NSLayoutConstraint.activate([
            posterView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            posterView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 12),
            posterView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12),
            posterView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            posterView.widthAnchor.constraint(equalToConstant: 60),
            posterView.heightAnchor.constraint(equalToConstant: 90),
            
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: posterView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            
            yearLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            yearLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            yearLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            yearLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask = nil
        posterView.image = UIImage(named: "photo")
        titleLabel.text = nil
        yearLabel.text = nil
    }
    
    func configure (with movie: Movie) {
        titleLabel.text = movie.title
        yearLabel.text = movie.year
    }
    
    func confugure(with movie: Movie){
        titleLabel.text = movie.title
        yearLabel.text = movie.year
        
        imageTask?.cancel()
        posterView.image = UIImage(systemName: "photo")
        guard let url = movie.posterURL else{
            return
        }
        
        imageTask = Task{[weak self] in
            guard let self else{
                return
            }
            if let image = try? await ImageLoader.shared.image(from: url) {
                // UI dəyişiklikləri MainActor-da
                await MainActor.run {
                    // Reuse zamanı cell artıq başqa data ola bilər — sadəcə göstər
                    self.posterView.image = image
                }
            }
        }
    }
}
