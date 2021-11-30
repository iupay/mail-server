const PubSub = require("@google-cloud/pubsub").PubSub;

let topic;

exports.register = function() {
    const client = new PubSub();
    topic = client.topic('<TOPICNAME>');
    this.register_hook('queue', 'send');
};

exports.send = async function(next, connection) {
    const plugin = this;

    connection.transaction.message_stream.get_data(async data => {
        await topic.publish(data);
        return next();
    });
}
