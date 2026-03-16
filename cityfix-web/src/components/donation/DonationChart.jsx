import React, { useEffect, useRef } from 'react';
import {
    Chart as ChartJS,
    CategoryScale,
    LinearScale,
    PointElement,
    LineElement,
    BarElement,
    Title,
    Tooltip,
    Legend,
    ArcElement
} from 'chart.js';
import { Line, Bar, Doughnut } from 'react-chartjs-2';
import './DonationChart.css';

ChartJS.register(
    CategoryScale,
    LinearScale,
    PointElement,
    LineElement,
    BarElement,
    Title,
    Tooltip,
    Legend,
    ArcElement
);

const DonationChart = ({ donations, trends }) => {
    const [chartType, setChartType] = React.useState('trends');

    const getTrendsChartData = () => {
        if (!trends || trends.length === 0) return null;

        return {
            labels: trends.map(t => t.period),
            datasets: [
                {
                    label: 'Donation Amount (₹)',
                    data: trends.map(t => t.totalAmount),
                    borderColor: 'rgb(37, 99, 235)',
                    backgroundColor: 'rgba(37, 99, 235, 0.1)',
                    tension: 0.4,
                    fill: true
                },
                {
                    label: 'Number of Donations',
                    data: trends.map(t => t.donationCount),
                    borderColor: 'rgb(34, 197, 94)',
                    backgroundColor: 'rgba(34, 197, 94, 0.1)',
                    tension: 0.4,
                    yAxisID: 'y1'
                }
            ]
        };
    };

    const getCenterDistributionData = () => {
        if (!donations || donations.length === 0) return null;

        const centerMap = new Map();
        donations.forEach(donation => {
            const centerName = donation.centerName;
            centerMap.set(centerName, (centerMap.get(centerName) || 0) + donation.amount);
        });

        const centers = Array.from(centerMap.entries()).sort((a, b) => b[1] - a[1]);

        return {
            labels: centers.map(([name]) => name),
            datasets: [
                {
                    data: centers.map(([, amount]) => amount),
                    backgroundColor: [
                        'rgba(37, 99, 235, 0.8)',
                        'rgba(34, 197, 94, 0.8)',
                        'rgba(245, 158, 11, 0.8)',
                        'rgba(239, 68, 68, 0.8)',
                        'rgba(139, 92, 246, 0.8)'
                    ],
                    borderColor: [
                        'rgb(37, 99, 235)',
                        'rgb(34, 197, 94)',
                        'rgb(245, 158, 11)',
                        'rgb(239, 68, 68)',
                        'rgb(139, 92, 246)'
                    ],
                    borderWidth: 2
                }
            ]
        };
    };

    const getMonthlyDistributionData = () => {
        if (!donations || donations.length === 0) return null;

        const monthlyData = new Array(12).fill(0);
        const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

        donations.forEach(donation => {
            const date = donation.createdAt?.toDate ? donation.createdAt.toDate() : new Date(donation.createdAt);
            monthlyData[date.getMonth()] += donation.amount;
        });

        return {
            labels: monthNames,
            datasets: [
                {
                    label: 'Monthly Donations (₹)',
                    data: monthlyData,
                    backgroundColor: 'rgba(37, 99, 235, 0.6)',
                    borderColor: 'rgb(37, 99, 235)',
                    borderWidth: 1
                }
            ]
        };
    };

    const chartOptions = {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            legend: {
                position: 'top',
            },
            title: {
                display: true,
                text: getChartTitle()
            }
        },
        scales: chartType === 'trends' ? {
            y: {
                type: 'linear',
                display: true,
                position: 'left',
                title: {
                    display: true,
                    text: 'Amount (₹)'
                }
            },
            y1: {
                type: 'linear',
                display: true,
                position: 'right',
                title: {
                    display: true,
                    text: 'Count'
                },
                grid: {
                    drawOnChartArea: false,
                }
            }
        } : {
            y: {
                beginAtZero: true,
                title: {
                    display: true,
                    text: 'Amount (₹)'
                }
            }
        }
    };

    const doughnutOptions = {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            legend: {
                position: 'right',
            },
            title: {
                display: true,
                text: 'Donations by Welfare Center'
            }
        }
    };

    function getChartTitle() {
        switch (chartType) {
            case 'trends': return 'Donation Trends Over Time';
            case 'centers': return 'Donations by Welfare Center';
            case 'monthly': return 'Monthly Donation Distribution';
            default: return 'Donation Analytics';
        }
    }

    const renderChart = () => {
        switch (chartType) {
            case 'trends':
                const trendsData = getTrendsChartData();
                return trendsData ? <Line data={trendsData} options={chartOptions} /> : <div className="no-data">No trend data available</div>;
            
            case 'centers':
                const centerData = getCenterDistributionData();
                return centerData ? <Doughnut data={centerData} options={doughnutOptions} /> : <div className="no-data">No center data available</div>;
            
            case 'monthly':
                const monthlyData = getMonthlyDistributionData();
                return monthlyData ? <Bar data={monthlyData} options={chartOptions} /> : <div className="no-data">No monthly data available</div>;
            
            default:
                return <div className="no-data">Select a chart type</div>;
        }
    };

    return (
        <div className="donation-chart">
            <div className="chart-header">
                <h3>Donation Analytics</h3>
                <div className="chart-controls">
                    <select 
                        value={chartType} 
                        onChange={(e) => setChartType(e.target.value)}
                        className="chart-type-select"
                    >
                        <option value="trends">Trends</option>
                        <option value="centers">By Center</option>
                        <option value="monthly">Monthly</option>
                    </select>
                </div>
            </div>
            <div className="chart-container">
                {renderChart()}
            </div>
        </div>
    );
};

export default DonationChart;