import UIKit

final class MoviesListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let searchController = UISearchController(searchResultsController: nil)

    private var results: [Movie] = []

    private var searchTask: Task<Void, Never>?

    private let emptyLabel: UILabel = {
        let lb = UILabel()
        lb.text = "Type to search movies…"
        lb.textColor = .secondaryLabel
        lb.textAlignment = .center
        lb.numberOfLines = 0
        return lb
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Movies"
        view.backgroundColor = .systemBackground

        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(MovieCell.self, forCellReuseIdentifier: MovieCell.reuseId)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 112
        tableView.backgroundView = emptyLabel

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search movies (title)"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        results.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let m = results[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: MovieCell.reuseId, for: indexPath) as! MovieCell
        cell.configure(with: .init(id: m.id, title: m.title, year: m.year,posterURL: m.posterURL))
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let m = results[indexPath.row]
        navigationController?.pushViewController(MoviesDetailViewController(movie: m), animated: true)
    }

    private func setEmpty(_ text: String) {
        emptyLabel.text = text
        tableView.backgroundView = emptyLabel
    }

    private func clearEmpty() {
        tableView.backgroundView = nil
    }
}

extension MoviesListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let query = (searchController.searchBar.text ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard query.count >= 2 else {
            searchTask?.cancel()
            results.removeAll()
            tableView.reloadData()
            setEmpty("Type at least 2 characters…")
            return
        }

        searchTask?.cancel()
        searchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000)

            guard !Task.isCancelled else { return }
            do {
                let items = try await APIClient.shared.searchMovies(query: query)
                await MainActor.run {
                    self?.results = items
                    self?.tableView.reloadData()
                    self?.clearEmpty()
                    if items.isEmpty { self?.setEmpty("No results for “\(query)”") }
                }
            } catch {
                await MainActor.run {
                    self?.results = []
                    self?.tableView.reloadData()
                    self?.setEmpty("Error: \(error.localizedDescription)")
                }
            }
        }
    }
}
