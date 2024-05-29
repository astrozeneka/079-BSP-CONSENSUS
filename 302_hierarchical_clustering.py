import numpy as np
from scipy.cluster.hierarchy import dendrogram, linkage
import matplotlib.pyplot as plt


male_bed = "data/ltrpred/consensus-male_ltrpred/consensus-male_LTRpred.bed"
female_bed = "data/ltrpred/consensus-female_ltrpred/consensus-female_LTRpred.bed"

if __name__ == '__main__':
    # Example 1D coordinates
    # X = np.array([1, 2, 5, 6, 9, 10, 12, 15])
    X = []
    labels = []

    for i, file in enumerate([male_bed, female_bed]):
        data = open(file, 'r').read().strip().split('\n')
        data = [x.split('\t') for x in data]
        labels += [x[3] for x in data]
        data = [(int(x[1]) + int(x[2]))//2 for x in data]
        X = X+data

    X = np.array(X)
    labels = np.array(labels)
    # Example 1D coordinates

    # Reshape to 2D array for linkage function
    X_reshape = X.reshape(-1, 1)
    labels_reshape = labels.reshape(-1, 1)

    # Calculate the linkage matrix using hierarchical clustering
    linkage_matrix = linkage(X_reshape, 'single')  # 'single' linkage is just an example, you can use other methods like 'complete', 'average', etc.

    # Plot the dendrogram with 90 rotated degrees
    plt.figure(figsize=(25, 10))

    # dendrogram(linkage_matrix, labels=X)
    dendrogram(linkage_matrix, orientation="right", labels=labels)
    plt.title('Hierarchical Clustering Dendrogram')
    plt.xlabel('Data Points')
    plt.ylabel('Distance')
    # Save svg
    plt.savefig("figures/hierarchical_clustering.svg", format="svg")
    print()