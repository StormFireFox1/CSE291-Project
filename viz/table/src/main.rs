use std::{
	collections::BTreeMap,
	io::{stdin, BufRead},
};

use clap::Parser;

#[derive(Parser)]
struct Args {
	#[arg(short, long)]
	flip: bool,
}

fn main() {
	let args = Args::parse();
	// (service type, (instance type, (config 1, (config 2, score))))
	let mut map = BTreeMap::new();
	let mut app = None;
	for line in stdin().lock().lines() {
		let cols: Vec<String> = line.unwrap().split('\t').map(|s| s.to_owned()).collect();
		if app.is_none() {
			app = Some(cols[0].clone());
		}
		let (conf_a, conf_b) = if args.flip { (3, 4) } else { (4, 3) };
		map.entry(cols[1].clone())
			.or_insert(BTreeMap::new())
			.entry(cols[2].clone())
			.or_insert(BTreeMap::new())
			.entry(cols[conf_a].clone())
			.or_insert(BTreeMap::new())
			.insert(cols[conf_b].clone(), cols[5].parse::<f64>().unwrap());
	}
	{
		print!("{}\t", app.unwrap());
		let (_, map) = map.iter().take(1).next().unwrap();
		for (instance, map) in map.iter() {
			for (conf_a, map) in map.iter() {
				for (conf_b, _) in map.iter() {
					print!("{instance}/{conf_a}/{conf_b}\t");
				}
			}
		}
		println!();
	}
	for (service, map) in map.iter() {
		print!("{service} \t");
		for (_, map) in map.iter() {
			for (_, map) in map.iter() {
				for (_, ref score) in map.iter() {
					print!("{score}\t")
				}
			}
		}
		println!();
	}
}
