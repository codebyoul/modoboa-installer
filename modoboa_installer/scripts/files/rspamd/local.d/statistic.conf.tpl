# Rspamd Bayesian classifier configuration
# Based on mailcow defaults
# Installed by modoboa-installer

classifier "bayes" {
    # Use Lua-based learning conditions
    learn_condition = 'return require("lua_bayes_learn").can_learn';

    # Use new schema format for storage
    new_schema = true;

    # Tokenizer: Orthogonal Sparse Bigram (recommended)
    tokenizer {
        name = "osb";
    }

    # Backend: Redis for persistence
    backend = "redis";

    # Minimum tokens required for classification
    min_tokens = 11;

    # Minimum learns before classifier activates
    min_learns = 5;

    # Token expiry: 90 days (7776000 seconds)
    expire = 7776000;

    # HAM statistics (legitimate mail)
    statfile {
        symbol = "BAYES_HAM";
        spam = false;
    }

    # SPAM statistics (unwanted mail)
    statfile {
        symbol = "BAYES_SPAM";
        spam = true;
    }

    # Autolearning configuration
    autolearn {
        # Learn as spam if score >= 12.0
        spam_threshold = 12.0;

        # Learn as ham if score <= -4.5
        ham_threshold = -4.5;

        # Ensure balanced learning between ham and spam
        check_balance = true;
        min_balance = 0.9;
    }
}
