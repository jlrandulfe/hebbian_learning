#!/usr/bin/env python3
"""
Script for drawing the shape of the Hebbian rule.
"""
# Standard libraries
import math
import os
# Third-party libraries
import matplotlib.pyplot as plt
import numpy as np


def format_plotting():
    plt.rcParams['figure.figsize'] = (10, 8)
    plt.rcParams['font.size'] = 22
    #    plt.rcParams['font.family'] = 'Times New Roman'
    plt.rcParams['axes.labelsize'] = plt.rcParams['font.size']
    plt.rcParams['axes.titlesize'] = 1.2 * plt.rcParams['font.size']
    plt.rcParams['legend.fontsize'] = 0.9 * plt.rcParams['font.size']
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
    plt.rcParams['legend.loc'] = 'upper right'
    plt.rcParams['axes.linewidth'] = 1
    plt.rcParams['lines.linewidth'] = 1
    plt.rcParams['lines.markersize'] = 3

    plt.gca().spines['right'].set_color('none')
    plt.gca().spines['top'].set_color('none')
    plt.gca().xaxis.set_ticks_position('bottom')
    plt.gca().yaxis.set_ticks_position('left')
    return

def leaky_only_noise(u_rest=-70, u_thres=-54, noise=0.02, R=65, C=8):
    """
    Simulate a Leaky neuron with Gauss noise addition on every iteration
    """
    # Gather real data
    data = np.genfromtxt("data/voltage.csv", delimiter=None, skip_header=1)
    data /= 1000.0
    # Simulate neuron voltage
    leaky_k = math.exp(-1/(R*C))
    iterations = 10000
    voltages = np.zeros(iterations)
    voltages[0] = u_rest
    for i in range(iterations-1): 
        voltages[i+1] = u_rest + (voltages[i]-u_rest)*leaky_k + noise

    # Plot real and simulated data
    plt.plot(voltages, "b")
    plt.plot(data, "g")
    plt.title("R={} MOhms, C={} nF, Noise={}".format(R, C, noise))
    plt.axhline(y=-70, color='r', linestyle="--")
    plt.axhline(y=-54, color='r', linestyle="--")
    plt.ylim(u_rest-1, u_thres+1)
    format_plotting()
    plt.grid()
    plt.xlabel("t [ms]")
    plt.ylabel("U(t) [mV]")
    script_path = os.path.dirname(os.path.realpath(__file__))
    plt.savefig('{}/results/leaky_noisy.eps'.format(script_path),
                bbox_inches='tight')
    plt.show()
    return

def main():
    leaky_only_noise()
    return


if __name__ == "__main__":
    main()
