#!/usr/bin/env python3
"""
Script for drawing the evolution of a neuron kinematics
"""
# Standard libraries
import os
# Third-party libraries
import matplotlib
import matplotlib.pyplot as plt
import numpy as np
from scipy import signal


def format_plotting():
    plt.rcParams['figure.figsize'] = (10, 8)
    plt.rcParams['font.size'] = 25
    #    plt.rcParams['font.family'] = 'Times New Roman'
    plt.rcParams['axes.labelsize'] = plt.rcParams['font.size']
    plt.rcParams['axes.titlesize'] = 1.2 * plt.rcParams['font.size']
    plt.rcParams['legend.fontsize'] = 0.7 * plt.rcParams['font.size']
    plt.rcParams['xtick.labelsize'] = 0.6 * plt.rcParams['font.size']
    plt.rcParams['ytick.labelsize'] = 0.6 * plt.rcParams['font.size']
    plt.rcParams['savefig.dpi'] = 1000
    plt.rcParams['savefig.format'] = 'eps'
    plt.rcParams['xtick.major.size'] = 3
    plt.rcParams['xtick.minor.size'] = 3
    plt.rcParams['xtick.major.width'] = 1
    plt.rcParams['xtick.minor.width'] = 1
    plt.rcParams['ytick.major.size'] = 3
    plt.rcParams['ytick.minor.size'] = 3
    plt.rcParams['ytick.major.width'] = 1
    plt.rcParams['ytick.minor.width'] = 1
    plt.rcParams['legend.frameon'] = True
    plt.rcParams['legend.loc'] = 'upper center'
    plt.rcParams['axes.linewidth'] = 1
    plt.rcParams['lines.linewidth'] = 1
    plt.rcParams['lines.markersize'] = 3

    plt.gca().spines['right'].set_color('none')
    plt.gca().spines['top'].set_color('none')
    return


def plot_1D_histogram(datafile="data/firing_times.csv"):
    """
    Plot the histogram of the firing times of an agent
    """
    # Import data and prepare plot
    data = np.genfromtxt(datafile, delimiter=",", skip_header=1)
    n, bins, patches = plt.hist(data, bins=100, range=(0, 3000), edgecolor="k",
                                density=True)

    # Set plots format
    format_plotting()
    plt.xlabel("t [ms]")
    plt.ylabel("P")

    # Save and show results
    script_path = os.path.dirname(os.path.realpath(__file__))
    plt.savefig('{}/results/firing_times.eps'.format(script_path),
                bbox_inches='tight')

    print("Data mean: {}".format(data.mean()))
    print("Data std. deviation: {}".format(data.std()))
    print("Data median: {}".format(np.median(data)))
    plt.show()
    return


def plot_2D_scatterplot(datafile="data/firing_correlations.csv"):
    """
    Plot the 2-D scatter plot of 3 neurons timing differences
    """
    # Import data and prepare plot
    data = np.genfromtxt(datafile, delimiter=",", skip_header=1)
    plt.scatter(data[:,0], data[:,1])

    # Get covariance
    cov_matrix = np.cov(data, rowvar=False)
    mean = data.mean(axis=0)
    print("mean vector mu_hat=[{}, {}]".format(mean[0], mean[1]))
    print("Covariance matrix: ")
    print(cov_matrix)

    # Set plots format
    format_plotting()

    # Save and show results
    script_path = os.path.dirname(os.path.realpath(__file__))
    plt.savefig('{}/results/firing_correlations.eps'.format(script_path),
            bbox_inches='tight')
    plt.show()
    return


def plot_2D_histogram(datafile="data/firing_correlations.csv"):
    """
    Plot the 2-D histogram of 3 neurons timing differences
    """
    # Import data and prepare plot
    data = np.genfromtxt(datafile, delimiter=",", skip_header=1)
    times_1 = data[:,0]
    times_2 = data[:,1]
    plt.hist2d(times_1, times_2, bins=180, normed=False,
               norm=matplotlib.colors.LogNorm(), cmap=plt.cm.get_cmap('summer'))
    plt.colorbar()

    # Set plots format
    format_plotting()
    plt.title("Ext. Coincidence Detector 2-D Hist")
    plt.xlabel(r"$\Delta t_{14} \quad [ms]$")
    plt.ylabel(r"$\Delta t_{24} \quad [ms]$")

    # Save and show results
    script_path = os.path.dirname(os.path.realpath(__file__))
    plt.savefig('{}/results/firing_2d_histogram.eps'.format(script_path),
            bbox_inches='tight')
    plt.show()
    return


def main():
    plot_2D_histogram()


if __name__ == "__main__":
    main()
