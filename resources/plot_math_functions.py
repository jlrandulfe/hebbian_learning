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


def hebbian_rule(tau=10):
    """
    Draw a plot of the EPSC rule (Hebb's rule).
    """
    t = np.arange(-50, 50, 1)
    # Create the data array. Non linear equation divided in 2 parts,
    # plus the zero.
    data1 = -np.exp(-np.abs(t[:50])/tau)
    data2 = np.exp(-np.abs(t[51:])/tau)
    data = np.hstack((data1, 0, data2))
    # Plot data
    format_plotting()
    plt.plot(t, data)
    plt.grid()
    plt.xlabel("Time difference [ms]")
    plt.ylabel("EPSC amplitude")
    script_path = os.path.dirname(os.path.realpath(__file__))
    plt.savefig('{}/results/epsc_plot.eps'.format(script_path), bbox_inches='tight')
    plt.show()
    return


def sigmoid_function(natural_period=1000, time_step=1, u_rest=-70, u_thres=-54,
                     u_ref=-62.5, x_0=-54):
    """
    Draw the plot of the Sigmoid function.
    """
    # Get the probability of 50 percent of spiking before the natural period
    trials = natural_period / time_step
    p = 1 - (1-0.5)**(1/trials)
    print("Probability of spiking at U_ref = {}".format(p))
    # Create the data array, using the sigmoid equation
    u = (np.arange(u_rest-1, u_thres+10, .1)).astype(np.float)
    # Narrow the effective area of the Sigmoid function.
    limit_inf = u_rest
    limit_sup = u_thres
    norm_u = (u-limit_inf) / (limit_sup-limit_inf)
    norm_x0 = (x_0-limit_inf) / (limit_sup-limit_inf)
    norm_uref = (u_ref-limit_inf) / (limit_sup-limit_inf)
    k = (math.log(p) - math.log(1-p)) / (norm_uref-norm_x0)
    print("Normalized x_0 = {}".format(norm_x0))
    print("Sigmoid k = {}".format(k))
    data = 1 / (1+np.exp(-k*(norm_u-norm_x0)))
    # Plot data
    format_plotting()
    plt.plot(u, data)
    plt.axvline(x=-70, color='r', linestyle="--")
    plt.axvline(x=-54, color='r', linestyle="--")
    plt.grid()
    plt.xlabel("U(t) [mV]")
    plt.ylabel("S(x)")
    plt.title("K={0:.2f}, X_0={1}".format(k, x_0))
    script_path = os.path.dirname(os.path.realpath(__file__))
    plt.savefig('{}/results/sigmoid_plot.eps'.format(script_path), bbox_inches='tight')
    plt.show()
    return


def main(f="hebbian"):
    if f=="hebbian":
        hebbian_rule()
    elif f=="sigmoid":
        sigmoid_function()
    return


if __name__ == "__main__":
    function = "sigmoid"
    main(function)
