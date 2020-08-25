const AWS = require('aws-sdk');
const s3 = new AWS.S3({apiVersion: '2006-03-01'});
const dateFormat = require('dateformat');

exports.handler = (event, context, callback) => {
    let date = new Date();
    date.setDate(date.getDate() - 1);

    const prefix = dateFormat(date, "UTC:yyyy'/'mm'/'dd'/'");
    const buckets = process.env.BUCKETS.split(',');

    let successes = {};
    let errors = {};
    let promises = [];

    buckets.forEach((bucket) => {

        const p = new Promise((resolve) => {
            s3.listObjectsV2({
                Bucket: bucket,
                Prefix: prefix,
                MaxKeys: 1,
            }, function (err, data) {
                if (err) {
                    errors[bucket] = err.message;
                } else if (data && data.Contents && data.Contents.length > 0) {
					successes[bucket] = `backups ok on ${bucket}/${prefix}`;
				} else {
					errors[bucket] = `backups failure on ${bucket}/${prefix}`;
                }
                resolve();
            });

        });
        promises.push(p);
    });

    Promise.all(promises).then(() => {
        console.log(successes);
        console.log(errors);
        callback(Object.keys(errors).length ? errors : null, successes);
    });
};
