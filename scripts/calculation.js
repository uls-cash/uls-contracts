const BN = require('bignumber.js');

const fs = require('fs');
const { stringify } = require('csv-stringify/sync');



const decimals = 18;
BN.set({
  DECIMAL_PLACES: decimals,
  ROUNDING_MODE: BN.ROUND_DOWN,
});

console.log();
const oneYearSeconds = 365 * 24 * 60 * 60;
console.log('oneYearSeconds:  ', oneYearSeconds);

const oneDaySeconds = 24 * 60 * 60;
console.log('oneDaySeconds:   ', oneDaySeconds);
console.log();

// k:               1.618033988749894848
const k1 = BN(BN('1.6180339887498948482045868343656381177203091798057628621354486227052604628189').toFixed(18));
console.log('k1:              ', k1.toFixed(18));

// k2:              0.618033988749894848
const k2 = BN(BN('1.0').dividedBy(k1).toFixed(18));
console.log('k2:              ', k2.toFixed(18));

// k3:              0.381966011250105152
const k3 = BN(BN('1.0').minus(k2).toFixed(18));
console.log('k3:              ', k3.toFixed(18));
console.log();


function main() {

  const totalSupply = BN(10000000);
  const totalLiquidity = totalSupply.multipliedBy('1000000').multipliedBy(k3).dividedBy('1000000');


  const totalStakingPre = totalSupply.minus(totalLiquidity);
  const totalStaking = BN('6180339.887498944824912000'); // totalStakingPre; // BN('6180339.887498944824912000');
  console.log('totalStakingPre: ', totalStakingPre.toFixed(18));

  // 2360679.774997896964574700
  const oneYearTotal = totalStakingPre.multipliedBy(k3).plus('0.000000000000000000');
  console.log('oneYearTotal:    ', oneYearTotal.toFixed(18));

  // 0.074856664605463500
  const rateStartSec = oneYearTotal.dividedBy(oneYearSeconds).plus('0.000000000000000000');
  console.log('rateStartSec:    ', rateStartSec.toFixed(18));


  // Calculation by year
  {
    // csv data
    const columns = [
      'Year',
      'Rate Per Second',
      'Rate Per Day',
      'Rewards', 'Total Rewards',
      'Total Rewards Percent', 'Total',
    ];
    const records = [{
      'Year': 0,
      'Rate Per Second': 0,
      'Rate Per Day': 0,
      'Rewards': 0,
      'Total Rewards': 0,
      'Total Rewards Percent': 0.0,
      'Total': totalStaking.toFixed(18),
    }];


    let totalRewards = BN(0);
    let year = 0;
    let yearsTotal = 80;
    let ratePerSec = rateStartSec;
    console.log();
    while (year <= yearsTotal) {
      if (year === 0) {
        ratePerSec = rateStartSec;
      } else {
        ratePerSec = BN(BN(ratePerSec).multipliedBy(k2).toFixed(18));
      }

      const rewards = BN(ratePerSec.multipliedBy(oneYearSeconds).toFixed(18));
      totalRewards = totalRewards.plus(rewards);

      year++;
      records.push({
        'Year': year,
        'Rate Per Second': ratePerSec.toFixed(18),
        'Rate Per Day': ratePerSec.multipliedBy(oneDaySeconds).toFixed(18),
        'Rewards': rewards.toFixed(18),
        'Total Rewards': totalRewards.toFixed(18),
        'Total Rewards Percent': totalRewards.dividedBy(totalStaking).toFixed(18),
        'Total': totalStaking.toFixed(18),
      });
      console.log('year:', year, 'rewards:', rewards.toFixed(18));
    }
    console.log();

    const csvData = stringify(
      records,
      { columns, header: true, }
    );
    fs.writeFileSync('./data/staking-by-year.csv', csvData);
  }

  let totalRewardsGlobal = BN(0);
  // Calculation by day
  {
    // csv data
    const columns = [
      'Day',
      'Rate Per Second',
      'Rate Per Day',
      'Rewards', 'Total Rewards',
      'Total Rewards Percent', 'Total',
    ];
    const records = [{
      'Day': 0,
      'Rate Per Second': 0,
      'Rate Per Day': 0,
      'Rewards': 0,
      'Total Rewards': 0,
      'Total Rewards Percent': 0.0,
      'Total': totalStaking.toFixed(18),
    }];


    let totalRewards = BN(0);
    let day = 0;
    let year = 0;
    let yearsTotal = 80;
    let ratePerSec = rateStartSec;
    console.log();
    while (year < yearsTotal) {
      if (Math.floor(day / 365) > year) {
        year++;
        ratePerSec = BN(BN(ratePerSec).multipliedBy(k2).toFixed(18));
      }

      const rewards = BN(ratePerSec.multipliedBy(oneDaySeconds).toFixed(18));
      totalRewards = totalRewards.plus(rewards);

      day++;
      records.push({
        'Day': day,
        'Rate Per Second': ratePerSec.toFixed(18),
        'Rate Per Day': ratePerSec.multipliedBy(oneDaySeconds).toFixed(18),
        'Rewards': rewards.toFixed(18),
        'Total Rewards': totalRewards.toFixed(18),
        'Total Rewards Percent': totalRewards.dividedBy(totalStaking).toFixed(18),
        'Total': totalStaking.toFixed(18),
      });
      console.log('year:', year + 1, 'day:', day, 'rewards:', rewards.toFixed(18));
    }
    totalRewardsGlobal = totalRewards;
    console.log();

    const csvData = stringify(
      records,
      { columns, header: true, }
    );
    fs.writeFileSync('./data/staking-by-day.csv', csvData);
  }


  console.log('totalSupply:     ', totalSupply.toFixed(18));
  console.log('totalStaking:     ', totalRewardsGlobal.toFixed(18));
  console.log('totalLiquidity:     ', totalSupply.minus(totalRewardsGlobal).toFixed(18));
  console.log();
}

main();
